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
      params[:to] = "Record.find_by_id" unless params.has_key?(:to)
      route(:show, "GET", "/#{base}/:id", params)
    end

    def new(params={})
      params[:to] = "Record.new" unless params.has_key?(:to)
      route(:new, "GET", "/#{base}/new", params)
    end

    def index(params={})
      params[:to] = "Record.all" unless params.has_key?(:to)
      route(:index, "GET", "/#{base}", params)
    end

    def create(params={})
      params[:to] = "Record.create" unless params.has_key?(:to)
      route(:create, "POST", "/#{base}",
            {:redirect => :show, ValidationError => :new}.merge(params))
    end

    def edit(params={})
      params[:to] = "Record.find_by_id" unless params.has_key?(:to)
      route(:edit, "GET", "/#{base}/:id/edit", params)
    end

    def update(params={})
      params[:to] = "Record.find_and_update" unless params.has_key?(:to)
      route(:update, "PUT", "/#{base}/:id",
            {:redirect => :show, ValidationError => :edit}.merge(params))
    end

    def destroy(params={})
      params[:to] = "Record.destroy" unless params.has_key?(:to)
      route(:destroy, "DELETE", "/#{base}/:id",
            {:redirect => :index}.merge(params))
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
    attr_reader :name, :redirects

    def initialize(name, criteria, delegator, responder, redirects)
      @name = name
      @criteria = criteria
      @delegator = delegator
      @responder = responder
      @redirects = redirects
    end

    def self.for_resource(resource, action, http_method, path, params)
      route_options = RouteOptions.new(resource, params)
      criteria = RouteCriteria.new(http_method, path, route_options.requirements)
      delegator = Delegator.new(resource, route_options.delegate_name)
      new(action, criteria, delegator, route_options.responder_for(action), route_options)
    end

    def respond_to_request(request)
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

  class RouteCriteria
    attr_reader :path

    def initialize(http_method, path, requirements)
      @http_method = http_method
      @path = path
      @requirements = requirements
    end

    def match?(http_method, path)
      match_http_method?(http_method) &&
        match_path?(path) &&
        match_requirements?
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

    def match_requirements?
      @requirements.all?(&:match?)
    end
  end
end

