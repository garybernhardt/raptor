require "erb"

module Raptor
  class PlaintextResponder
    def initialize(text)
      @text = text
    end

    def respond(record, inference_sources)
      Rack::Response.new(@text)
    end
  end

  class RedirectResponder
    def initialize(resource, target_route_name)
      @resource = resource
      @target_route_name = target_route_name
    end

    def respond(record, inference_sources)
      response = Rack::Response.new
      path = @resource.routes.route_named(@target_route_name).path
      if record
        path = path.gsub(/:\w+/) do |match|
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
    def initialize(resource, template_name, presenter_class)
      @resource = resource
      @template_name = template_name
      @presenter_class = presenter_class
    end

    def respond(record, inference_sources)
      presenter = create_presenter(record, inference_sources)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      Template.render(presenter, template_path)
    end

    def template_path
      "#{@resource.path_component}/#{@template_name}.html.erb"
    end

    def create_presenter(record, inference_sources)
      sources = inference_sources.with_record(record).to_hash
      InfersArgs.new(@presenter_class.method(:new), sources).call
    end
  end

  class ActionTemplateResponder
    def initialize(resource, template_name)
      @resource = resource
      @template_name = template_name
    end

    def respond(record, inference_sources)
      responder = TemplateResponder.new(@resource,
                                        @template_name,
                                        presenter_class)
      responder.respond(record, inference_sources)
    end

    def plural?
      @template_name == :index
    end

    def presenter_class
      if plural?
        @resource.many_presenter
      else
        @resource.one_presenter
      end
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

