require 'erb'
require 'rack'

class Class
  def takes(*args)
    define_initialize(args)
  end

  def define_initialize(args)
    assignments = args.map { |a| "@#{a} = #{a}" }.join("\n")
    self.class_eval %{
      def initialize(#{args.join(", ")})
        #{assignments}
      end
    }
  end

  alias_method :let, :define_method
end

module Raptor
  def self.routes(resource, &block)
    resource = Resource.wrap(resource)
    Router.new(resource, &block)
  end

  class App
    def initialize(resources)
      @resources = resources
    end

    def call(env)
      request = Rack::Request.new(env)
      Raptor.log "App: routing #{request.request_method} #{request.path_info}"
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

    def action_target(action_name)
      @routes.find { |r| r.name == action_name }.path
    end
  end

  class BuildsRoutes
    def initialize(resource)
      @resource = resource
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      @routes
    end

    def show(delegate_name="Record.find_by_id")
      route(:show, "GET", "/#{base}/:id", delegate_name)
    end

    def new(delegate_name="Record.new")
      route(:new, "GET", "/#{base}/new", delegate_name)
    end

    def index(delegate_name="Record.all")
      route(:index, "GET", "/#{base}", delegate_name)
    end

    def create(delegate_name="Record.create")
      route(:create, "POST", "/#{base}", delegate_name,
            :redirect => :show)
    end

    def edit(delegate_name="Record.find_by_id")
      route(:edit, "GET", "/#{base}/:id/edit", delegate_name)
    end

    def update(delegate_name="Record.find_and_update")
      route(:update, "PUT", "/#{base}/:id", delegate_name,
            :redirect => :show)
    end

    def destroy(delegate_name="Record.destroy")
      route(:destroy, "DELETE", "/#{base}/:id", delegate_name,
            :redirect => :index)
    end

    def base
      @resource.path_component
    end

    def route(action, http_method, path, delegate_name, redirects={})
      criteria = RouteCriteria.new(http_method, path)
      delegator = Delegator.new(@resource, delegate_name)
      if redirects.empty?
        responder = TemplateResponder.new(@resource, action)
      else
        responder = RedirectResponder.new(@resource,
                                          action,
                                          redirects.fetch(:redirect))
      end
      @routes << Route.new(action, criteria, delegator, responder)
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    attr_reader :name

    def initialize(name, criteria, delegator, responder)
      @name = name
      @criteria = criteria
      @delegator = delegator
      @responder = responder
    end

    def call(request)
      record = @delegator.delegate(request, @criteria.path)
      inference_sources = InferenceSources.new(request, path)
      @responder.respond(record, inference_sources)
    end

    def path
      @criteria.path
    end

    def match?(request)
      @criteria.match?(request.request_method, request.path_info)
    end
  end

  class RedirectResponder
    def initialize(resource, template_name, target)
      @resource = resource
      @template_name = template_name
      @target = target
    end

    def respond(record, inference_sources)
      response = Rack::Response.new
      target = @resource.routes.action_target(@target)
      if record
        target = target.gsub(/:id/, record.id.to_s) # XXX: Generalize replace
      else
        target = target
      end
      redirect_to(response, target)
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

  class Delegator
    def initialize(resource, delegate_name)
      @resource = resource
      @delegate_name = delegate_name
    end

    def delegate(request, route_path)
      Raptor.log("Delegating to #{@delegate_name}")
      sources = inference_sources(request, route_path)
      record = delegate_method.call(*delegate_args(sources))
      Raptor.log("Delegate returned #{record}")
      record
    end

    def delegate_args(sources)
      InfersArgs.new(delegate_method, sources).args
    end

    def delegate_method
      @resource.record_class.method(method_name)
    end

    def method_name
      @delegate_name.split('.').last.to_sym
    end

    def inference_sources(request, route_path)
      InferenceSources.new(request, route_path).to_hash
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

  class InferenceSources
    def initialize(request, route_path, record=nil)
      @request = request
      @route_path = route_path
      @record = record
    end

    def to_hash
      request_sources.merge(path_arg_sources).merge(record_sources)
    end

    def request_sources
      {:path => @request.path_info, :params => @request.params}
    end

    def path_arg_sources
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

    def record_sources
      @record ? {:record => @record} : {}
    end

    def with_record(record)
      InferenceSources.new(@request, @route_path, record)
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

    def routes
      @resource::Routes
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
      return false if components(@path).length != components(path).length
      path_component_pairs(path).all? do |route_component, path_component|
        route_component[0] == ':' && path_component || route_component == path_component
      end
    end

    def path_component_pairs(path)
      components(@path).zip(components(path))
    end

    def components(path)
      path.split('/')
    end
  end

  def self.log(text)
    puts "Raptor: #{text}" if ENV['RAPTOR_LOGGING']
  end
end

