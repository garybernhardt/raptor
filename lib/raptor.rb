require 'erb'

module Raptor
  def self.routes(resource)
    wrapped = Resource.wrap(resource)
    Router.new(resource, [
               Route.new('/posts/new', 'Posts::Record#new', 'new', wrapped),
               Route.new('/posts/:id', 'Posts::Record#find_by_id', 'show', wrapped)

    ])
  end

  class Router
    def initialize(resource, routes)
      @resource = resource
      @routes = routes
    end

    def call(env)
      incoming_path = env['PATH_INFO']
      route = @routes.find {|r| r.matches?(incoming_path) }
      route.call(env)
    end
  end

  class Route
    def initialize(path, domain_spec, template_name, resource)
      @path = RoutePath.new(path)
      @domain_spec = domain_spec
      @template_name = template_name
      @resource = resource
    end

    def call(env)
      incoming_path = env['PATH_INFO']
      args = @path.extract_args(incoming_path)
      record = @resource.record_class.send(domain_method(@domain_spec), *args)
      presenter = @resource.one_presenter.new(record)
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

