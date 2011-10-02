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
    def initialize(resource, template_name)
      @resource = resource
      @template_name = template_name
    end

    def respond(record, inference_sources)
      presenter = create_presenter(record, inference_sources)
      Rack::Response.new(template(presenter).render)
    end

    def template(presenter)
      Template.new(presenter, @resource.path_component, @template_name)
    end

    def create_presenter(record, inference_sources)
      sources = inference_sources.with_record(record).to_hash
      args = InfersArgs.new(presenter_class.method(:new), sources).args
      presenter_class.new(*args)
    end

    def presenter_class
      if plural?
        @resource.many_presenter
      else
        @resource.one_presenter
      end
    end

    def plural?
      @template_name == :index
    end
  end

  class Template
    def initialize(presenter, resource_path_component, template_name)
      @presenter = presenter
      @resource_path_component = resource_path_component
      @template_name = template_name
    end

    def exists?
      File.exists?(template_path)
    end

    def render
      template.result(@presenter.instance_eval { binding })
    end

    def template
      ERB.new(File.new(template_path).read)
    end

    def template_path
      "views/#{@resource_path_component}/#{@template_name}.html.erb"
    end
  end
end

