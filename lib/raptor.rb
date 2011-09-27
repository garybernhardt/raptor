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
      Raptor.log "App: routing #{request.path_info}"
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
    def initialize(resource, &block)
      @resource = resource
      @routes = BuildsRoutes.new(resource).build(&block)
    end

    def call(request)
      route = route_for_request(request)
      log_routing_of(route, request)
      route.call(request)
    end

    def log_routing_of(route, request)
      Raptor.log %{#{@resource.resource_name} routing #{request.path_info.inspect} to #{route.path.inspect}}
    end

    def route_for_request(request)
      @routes.find {|r| r.match?(request) } or raise NoRouteMatches
    end

  end

  class BuildsRoutes
    ROUTE_CRITERIA = {:show => ["GET", "/%s/:id"],
                      :new => ["GET", "/%s/new"],
                      :index => ["GET", "/%s"],
                      :create => ["POST", "/%s"],
    }

    DEFAULT_DELEGATE_NAMES = {:show => "Record.find_by_id",
                              :new => "Record.new",
                              :index => "Record.all",
                              :create => "Record.create"}
    def initialize(resource)
      @resource = resource
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      @routes
    end

    ROUTE_CRITERIA.each_pair do |method_name, criteria|
      http_method, path_template = criteria
      define_method(method_name) do |delegate_name=nil|
        route_path = path_template % @resource.path_component
        criteria = RouteCriteria.new(http_method, route_path)
        delegate_name ||= DEFAULT_DELEGATE_NAMES.fetch(method_name)
        @routes << Route.new(route_path,
                             criteria,
                             delegate_name,
                             method_name,
                             @resource)
      end
    end

  end

  class NoRouteMatches < RuntimeError; end

  class RouteResult
    def initialize(route, response, record)
      @route = route
      @response = response
      @record = record
    end

    def mutate_response
      if @route.template_name == :create
        @response.status = 403
        @response["Location"] = "/#{@route.resource.path_component}/#{@record.id}"
      end
      @response
    end
  end

  class Route
    attr_reader :path
    attr_reader :template_name
    attr_reader :resource

    def initialize(path, criteria, delegate_name, template_name, resource)
      @path = path
      @criteria = criteria
      @delegate_name = delegate_name
      @template_name = template_name
      @resource = resource
    end

    def call(request)
      inference_sources = InferenceSources.new(request, @path).to_hash
      delegator = Delegator.new(inference_sources, @resource, @delegate_name)
      record = delegator.delegate
      presenter = presenter_class.new(record)
      body = render(presenter)
      response = Rack::Response.new(body)
      RouteResult.new(self, response, record).mutate_response
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

    def match?(request)
      @criteria.match?(request.request_method, request.path_info)
    end

    def render(presenter)
      Template.new(presenter, @resource.path_component, @template_name).render
    end
  end

  class Delegator
    def initialize(inference_sources, resource, delegate_name)
      @inference_sources = inference_sources
      @resource = resource
      @delegate_name = delegate_name
    end

    def delegate
      delegate_method.call(*delegate_args)
    end

    def delegate_args
      InfersArgs.new(delegate_method, @inference_sources).args
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
    def initialize(request, route_path)
      @request = request
      @route_path = route_path
    end

    def to_hash
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
      @route_path.split('/').zip(@request.path_info.split('/'))
    end
  end

  class InfersArgs
    def initialize(method, sources)
      @method = method
      @sources = sources
    end

    def args
      parameters.select do |type, name|
        name && type != :rest && type != :block
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

    def initialize(http_method, path)
      @http_method = http_method
      @path = path
    end

    def match?(http_method, path)
      match_http_method?(http_method) && match_path?(path)
    end

    def match_http_method?(http_method)
      http_method == @http_method
    end

    def match_path?(path)
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

