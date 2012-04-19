module Raptor
  class PlaintextResponder
    def initialize(text)
      @text = text
    end

    def respond(route, subject, injector)
      Rack::Response.new(@text)
    end
  end

  class ActionRedirectResponder
    def initialize(app, target)
      @app = app
      @target = target
    end

    def respond(route, subject, injector)
      path = resource_path(route, subject)
      RedirectResponder.new(path).respond(route, subject, injector)
    end

    def resource_path(route, subject)
      path = route.neighbor_named(@target).path
      if subject
        path = path.gsub(/:\w+/) do |match|
          # XXX: Untrusted send
          subject.send(match.sub(/^:/, '')).to_s
        end
      end
      path
    end
  end

  class RedirectResponder
    def initialize(location)
      @location = location
    end

    def respond(route, subject, injector)
      response = Rack::Response.new
      Raptor.log("Redirecting to #{@location}")
      response.status = 302
      response["Location"] = @location
      response
    end
  end

  class TemplateResponder
    def initialize(app, presenter_name, template_path, path)
      @app = app
      @presenter_name = presenter_name
      @template_path = template_path
      @path = path
    end

    def respond(route, subject, injector)
      presenter = create_presenter(subject, injector)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      layout = FindsLayouts.find(@path)
      template = Template.from_path(template_path)
      layout.render(template, presenter)
    end

    def template_path
      "#{@template_path}.html.erb"
    end

    def create_presenter(subject, injector)
      injector = injector.add_subject(subject)
      injector.call(presenter_class.method(:new))
    end

    def presenter_class
      constant_name = Raptor::Util.camel_case(@presenter_name)
      @app.presenters.fetch(constant_name)
    end
  end

  class ActionTemplateResponder
    def initialize(app, presenter_name, parent_path, template_name)
      @app = app
      @presenter_name = presenter_name
      @parent_path = parent_path
      @template_name = template_name
    end

    def respond(route, subject, injector)
      responder = TemplateResponder.new(@app,
                                        @presenter_name,
                                        template_path,
                                        @parent_path)
      responder.respond(route, subject, injector)
    end

    def template_path
      # XXX: Support multiple template directories
      "#{@parent_path}/#{@template_name}"
    end
  end

end

