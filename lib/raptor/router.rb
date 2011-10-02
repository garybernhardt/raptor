module Raptor
  class Router
    def initialize(resource, routes)
      @resource = resource
      @routes = routes
    end

    def self.build(resource, &block)
      routes = BuildsRoutes.new(resource).build(&block)
      new(resource, routes)
    end

    def call(request)
      route = route_for_request(request)
      log_routing_of(route, request)
      begin
        route.respond_to_request(request)
      rescue Exception => e
        Raptor.log("Looking for a redirect for #{e.inspect}")
        handle_exception(request, route.redirects, e) or raise e
      end
    end

    def handle_exception(request, redirects, e)
      action = redirects.action_for_exception(e)
      if action
        route_named(action).respond_to_request(request)
      else
        false
      end
    end

    def log_routing_of(route, request)
      Raptor.log %{#{@resource.resource_name} routing #{request.path_info.inspect} to #{route.path.inspect}}
    end

    def route_for_request(request)
      @routes.find {|r| r.match?(request) } or raise NoRouteMatches
    end

    def route_named(action_name)
      @routes.find { |r| r.name == action_name }
    end
  end

  class BuildsRoutes
    def initialize(resource)
      @resource = resource
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      ValidatesRoutes.validate!(@routes)
      @routes
    end

    def show(params={})
      params[:to] = "#{mod}::Record.find_by_id" unless params.has_key?(:to)
      route(:show, "GET", "/#{base}/:id", params)
    end

    def new(params={})
      params[:to] = "#{mod}::Record.new" unless params.has_key?(:to)
      route(:new, "GET", "/#{base}/new", params)
    end

    def index(params={})
      params[:to] = "#{mod}::Record.all" unless params.has_key?(:to)
      route(:index, "GET", "/#{base}", params)
    end

    def create(params={})
      params[:to] = "#{mod}::Record.create" unless params.has_key?(:to)
      route(:create, "POST", "/#{base}",
            {:redirect => :show, ValidationError => :new}.merge(params))
    end

    def edit(params={})
      params[:to] = "#{mod}::Record.find_by_id" unless params.has_key?(:to)
      route(:edit, "GET", "/#{base}/:id/edit", params)
    end

    def update(params={})
      params[:to] = "#{mod}::Record.find_and_update" unless params.has_key?(:to)
      route(:update, "PUT", "/#{base}/:id",
            {:redirect => :show, ValidationError => :edit}.merge(params))
    end

    def destroy(params={})
      params[:to] = "#{mod}::Record.destroy" unless params.has_key?(:to)
      route(:destroy, "DELETE", "/#{base}/:id",
            {:redirect => :index}.merge(params))
    end

    def mod
      @resource.module_path
    end

    def base
      @resource.path_component
    end

    def route(action, http_method, path, params={})
      route = Route.for_resource(@resource, action, http_method, path, params)
      @routes << route
      route
    end
  end

  class RouteOptions
    def initialize(resource, params)
      @resource = resource
      @params = params
    end

    def delegate_name
      @params.fetch(:to)
    end

    def action_for_exception(e)
      @params.each_pair do |maybe_exception, maybe_action|
        if maybe_exception.is_a?(Class) && e.is_a?(maybe_exception)
          return maybe_action
        end
      end
      false
    end

    def responder_for(action)
      redirect = @params[:redirect]
      text = @params[:text]
      if redirect
        RedirectResponder.new(@resource, redirect)
      elsif text
        PlaintextResponder.new(text)
      else
        TemplateResponder.new(@resource, action)
      end
    end

    def requirements
      return [] unless @params.has_key?(:require)
      name = @params.fetch(:require).to_s
      Requirements.new(@resource).matching(name)
    end
  end

  class Requirements
    def initialize(resource)
      @resource = resource
    end

    def matching(name)
      requirement_name = Util.camel_case(name) + "Requirement"
      @resource.requirements.select do |requirement|
        requirement.name == requirement_name
      end
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    attr_reader :name, :path, :redirects

    def initialize(name, path, requirements, delegator, responder, redirects)
      @name = name
      @path = path
      @requirements = requirements
      @delegator = delegator
      @responder = responder
      @redirects = redirects
    end

    def self.for_resource(resource, action, http_method, path, params)
      route_options = RouteOptions.new(resource, params)
      requirements = route_options.requirements + [
        HttpMethodRequirement.new(http_method),
        PathRequirement.new(path),
      ]
      delegator = Delegator.new(route_options.delegate_name)
      responder = route_options.responder_for(action)
      new(action, path, requirements, delegator, responder, route_options)
    end

    def respond_to_request(request)
      record = @delegator.delegate(request, @path)
      inference_sources = InferenceSources.new(request, @path)
      @responder.respond(record, inference_sources)
    end

    def match?(request)
      # XXX: use a single request-wide InferenceSources
      inference_sources = InferenceSources.new(request, @path).to_hash
      RouteCriteria.new(@path, @requirements).match?(request)
    end
  end

  class RouteCriteria
    def initialize(path, requirements)
      @requirements = requirements
      @path = path
    end

    def match?(request)
      # XXX: use a single request-wide InferenceSources
      inference_sources = InferenceSources.new(request,
                                               request.path_info).to_hash
      @requirements.all? do |requirement|
        args = InfersArgs.new(requirement.method(:match?),
                              inference_sources).args
        requirement.match?(*args)
      end
    end
  end

  class HttpMethodRequirement
    def initialize(http_method)
      @http_method = http_method
    end

    def match?(http_method)
      http_method == @http_method
    end
  end

  class PathRequirement
    def initialize(path)
      @path = path
    end

    def match?(path)
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
end

