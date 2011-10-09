require "erb"

module Raptor
  class PlaintextResponder
    def initialize(text)
      @text = text
    end

    def respond(record, inference)
      Rack::Response.new(@text)
    end
  end

  class RedirectResponder
    def initialize(resource, target_route_name)
      @resource = resource
      @target_route_name = target_route_name
    end

    def respond(record, inference)
      response = Rack::Response.new
      path = @resource.routes.route_named(@target_route_name).path
      if record
        path = path.gsub(/:\w+/) do |match|
          # XXX: Untrusted send
          record.send(match.sub(/^:/, '')).to_s
        end
      end
      redirect_to(response, path)
      response
    end

    def redirect_to(response, location)
      Raptor.log("Redirecting to #{location}")
      response.status = 302
      response["Location"] = location
    end
  end

  class TemplateResponder
    def initialize(resource, presenter_name, template_name)
      @resource = resource
      @presenter_name = presenter_name
      @template_name = template_name
    end

    def respond(record, inference)
      presenter = create_presenter(record, inference)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      Template.render(presenter, template_path)
    end

    def template_path
      "#{@resource.path_component}/#{@template_name}.html.erb"
    end

    def create_presenter(record, inference)
      inference = inference.add_record(record)
      inference.call(presenter_class.method(:new))
    end

    def presenter_class
      @resource.send("#{@presenter_name}_presenter")
    end
  end

  class ActionTemplateResponder
    def initialize(resource, presenter_name, template_name)
      @resource = resource
      @presenter_name = presenter_name
      @template_name = template_name
    end

    def respond(record, inference)
      responder = TemplateResponder.new(@resource,
                                        @presenter_name,
                                        @template_name)
      responder.respond(record, inference)
    end
  end

  class Template
    def initialize(presenter, template_path)
      @presenter = presenter
      @template_path = template_path
    end

    def self.render(presenter, template_path)
      new(presenter, template_path).render
    end

    def render
      template.result(@presenter.instance_eval { binding })
    end

    def template
      ERB.new(File.new(full_template_path).read)
    end

    def full_template_path
      "views/#{@template_path}"
    end
  end
end

