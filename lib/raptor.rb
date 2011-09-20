require 'erb'

module Raptor
  def self.routes(resource)
    Router.new(resource, [
               Route.new('/posts/new', 'Posts::Record#new', 'new', resource),
               Route.new('/posts/:id', 'Posts::Record#find_by_id', 'show', resource)

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
    attr_reader :template_name
    def initialize(path, domain_spec, template_name, resource)
      @path = path
      @domain_spec = domain_spec
      @template_name = template_name
      @resource = resource
    end

    def call(env)
      incoming_path = env['PATH_INFO']
      args = args_from_incoming_path(incoming_path)
      record = record_class.send(domain_method(@domain_spec), *args)
      presenter = one_presenter.new(record)
      render(presenter, template_name)
    end

    def resource_name
      underscore(@resource.name.split('::').last)
    end

    def underscore(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end


    def matches?(path)
      zip_with_path(path).map do |route_component, path_component|
        (route_component[0] == ':' || route_component == path_component)
      end.all?
    end

    def args_from_incoming_path(path)
      zip_with_path(path).select do |route_component, path_component|
        route_component[0] == ':'
      end.map {|x| x[1].to_i } # all url args are numbers for now
    end

    def zip_with_path(path)
      @path.split('/').zip(path.split('/'))
    end

    def render(presenter, template_name)
      template = template_named(template_name)
      template_binder = TemplateBinder.new(resource_name.to_sym => presenter)
      template.result(template_binder.get_binding)
    end

    def template_named(route)
      template = ERB.new(File.new("views/#{resource_name}/#{route}.html.erb").read)
    end

    def record_class
      @resource.const_get(:Record)
    end

    def domain_method(domain_description)
      domain_description.split('#').last.to_sym
    end

    def one_presenter
      @resource.const_get(:PresentsOne)
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

