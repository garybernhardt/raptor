require 'erb'
require 'rack'

module Raptor
  def self.routes(resource, &block)
    resource = Resource.wrap(resource)
    Router.new(resource, &block)
  end

  class App
    def initialize(resources)
      @resources = resources
    end

    def call(request)
      @resources.each do |resource|
        begin
          return resource::Routes.call(request)
        rescue NoRouteMatches
          raise if resource == @resources.last
        end
      end
    end
  end

  class Router
    ROUTE_PATHS = {:show => "/%s/:id",
                   :new => "/%s/new",
                   :index => "/%s"}
    def initialize(resource, &block)
      @resource = resource
      @routes = []
      instance_eval(&block)
    end

    def call(request)
      incoming_path = request.path_info
      route_for_path(incoming_path).call(request)
    end

    def matches?(path)
      @routes.any? { |r| r.matches?(path) }
    end

    def route_for_path(incoming_path)
      @routes.find {|r| r.matches?(incoming_path) } or raise NoRouteMatches
    end

    [:show, :new, :index].each do |method_name|
      define_method(method_name) do |delegate_name=nil|
        route_path = ROUTE_PATHS.fetch(method_name) % @resource.resource_name
        @routes << Route.new(route_path,
                             delegate_name,
                             method_name,
                             @resource)
      end
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    def initialize(path, domain_spec, template_name, resource)
      @path = RoutePath.new(path)
      @domain_spec = domain_spec
      @template_name = template_name
      @resource = resource
    end

    def call(request)
      incoming_path = request.path_info
      args = @path.extract_args(incoming_path)
      if @domain_spec
        record = @resource.record_class.send(domain_method(@domain_spec), *args)
      end
      if record
        presenter = @resource.one_presenter.new(record)
      end
      render(presenter)
    end

    def matches?(path)
      @path.matches?(path)
    end

    def render(presenter)
      template = template_path
      template_binder = TemplateBinder.new(@resource.resource_name.to_sym => presenter)
      template.result(template_binder.get_binding)
    end

    def template_path
      template = ERB.new(File.new("views/#{@resource.resource_name}/#{@template_name}.html.erb").read)
    end

    def domain_method(domain_description)
      domain_description.split('#').last.to_sym
    end
  end

  class Resource
    def self.wrap(resource)
      new(resource)
    end

    def initialize(resource)
      @resource = resource
    end

    def resource_name
      underscore(@resource.name.split('::').last)
    end

    def underscore(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end

    def record_class
      @resource.const_get(:Record)
    end

    def one_presenter
      @resource.const_get(:PresentsOne)
    end
  end

  class RoutePath
    def initialize(path)
      @path = path
    end

    def matches?(path)
      path_component_pairs(path).map do |route_component, path_component|
        route_component[0] == ':' || route_component == path_component
      end.all?
    end

    def extract_args(path)
      path_component_pairs(path).select do |route_component, path_component|
        route_component[0] == ':'
      end.map {|x| x[1].to_i } # all url args are numbers for now
    end

    def path_component_pairs(path)
      path_components = path.split('/')
      self.components.zip(path_components)
    end

    def components
      @path.split('/')
    end
  end

  class TemplateBinder
    def initialize(params)
      @params = params
    end

    def method_missing(name)
      @params[name] or super
    end

    def get_binding
      binding
    end
  end
end

