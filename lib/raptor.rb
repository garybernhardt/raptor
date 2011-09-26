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
      Raptor.log "App: routing request to #{request.path_info}"
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

    DEFAULT_DELEGATE_NAMES = {:show => "Record.find_by_id",
                              :new => "Record.new",
                              :index => "Record.all"}

    def initialize(resource, &block)
      @resource = resource
      @routes = []
      instance_eval(&block)
    end

    def call(request)
      incoming_path = request.path_info
      route = route_for_path(incoming_path)
      Raptor.log %{#{@resource.resource_name} routing #{request.path_info.inspect} to #{route.path.path.inspect}} # XXX: path abstraction
      route.call(request)
    end

    def route_for_path(incoming_path)
      @routes.find {|r| r.matches?(incoming_path) } or raise NoRouteMatches
    end

    ROUTE_PATHS.each_pair do |method_name, path_template|
      define_method(method_name) do |delegate_name=nil|
        route_path = path_template % @resource.path_component
        delegate_name ||= DEFAULT_DELEGATE_NAMES.fetch(method_name)
        @routes << Route.new(route_path,
                             delegate_name,
                             method_name,
                             @resource)
      end
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    attr_reader :path

    def initialize(path, delegate_name, template_name, resource)
      @path = RouteCriteria.new(path)
      @delegate_name = delegate_name
      @template_name = template_name
      @resource = resource
    end

    def call(request)
      incoming_path = request.path_info
      record = Delegator.new(request, @path, @resource, @delegate_name).delegate
      presenter = presenter_class.new(record)
      render(presenter)
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

    def matches?(path)
      @path.matches?(path)
    end

    def render(presenter)
      Template.new(presenter, @resource.path_component, @template_name).render
    end
  end

  class Delegator
    def initialize(request, route_path, resource, delegate_name)
      @request = request
      @route_path = route_path
      @resource = resource
      @delegate_name = delegate_name
    end

    def delegate
      record = delegate_method.call(*delegate_args)
    end

    def delegate_args
      inference_sources = InferenceSources.new(@request,
                                               @route_path.path,
                                               @request.path_info).sources
      InfersArgs.new(delegate_method, inference_sources).args
    end

    def delegate_method
      @resource.record_class.method(method_name)
    end

    def method_name
      @delegate_name.split('.').last.to_sym
    end
  end

  class Template
    def initialize(presenter, resource_path_component, template_name)
      @presenter = presenter
      @resource_path_component = resource_path_component
      @template_name = template_name
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

  class InferenceSources
    def initialize(request, route_path, path)
      @request = request
      @route_path = route_path
      @path = path
    end

    def sources
      {:params => @request.params}.merge(extract_args)
    end

    def extract_args
      args = {}
      path_component_pairs.select do |route_component, path_component|
        route_component[0] == ':'
      end.each do |x, y|
        args[x[1..-1].to_sym] = y.to_i
      end
      args
    end

    def path_component_pairs
      @route_path.split('/').zip(@path.split('/'))
    end
  end

  class InfersArgs
    def initialize(method, sources)
      @method = method
      @sources = sources
    end

    def args
      parameters.select do |type, name|
        name && type != :rest
      end.map do |type, name|
        @sources.fetch(name)
      end
    end

    def parameters
      method_for_inference.parameters
    end

    def method_for_inference
      if @method.name == :new
        @method.receiver.instance_method(:initialize)
      else
        @method
      end
    end
  end

  class Resource
    def self.wrap(resource)
      new(resource)
    end

    def initialize(resource)
      @resource = resource
    end

    def path_component
      underscore(resource_name)
    end

    def resource_name
      @resource.name.split('::').last
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

    def many_presenter
      @resource.const_get(:PresentsMany)
    end
  end

  class RouteCriteria
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def matches?(path)
      path_component_pairs(path).map do |route_component, path_component|
        route_component[0] == ':' && path_component || route_component == path_component
      end.all?
    end

    def path_component_pairs(path)
      path_components = path.split('/')
      self.components.zip(path_components)
    end

    def components
      @path.split('/')
    end
  end

  def self.log(text)
    puts "Raptor: #{text}" if ENV['RAPTOR_LOGGING']
  end
end

