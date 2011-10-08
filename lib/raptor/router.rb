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
        action = route.action_for_exception(e) or raise
        route_named(action).respond_to_request(request)
      end
    end

    def log_routing_of(route, request)
      Raptor.log "#{@resource.resource_name} " +
        "routing #{request.path_info.inspect} to #{route.path.inspect}"
    end

    def route_for_request(request)
      @routes.find { |route| route.match?(request) } or raise NoRouteMatches
    end

    def route_named(action_name)
      @routes.find { |route| route.name == action_name }
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

    def show(params={})
      params[:to] = "#{mod}::Record.find_by_id" unless params.key?(:to)
      route(:show, "GET", "/#{base}/:id", params)
    end

    def new(params={})
      params[:to] = "#{mod}::Record.new" unless params.key?(:to)
      route(:new, "GET", "/#{base}/new", params)
    end

    def index(params={})
      params[:to] = "#{mod}::Record.all" unless params.key?(:to)
      route(:index, "GET", "/#{base}", params)
    end

    def create(params={})
      params[:to] = "#{mod}::Record.create" unless params.key?(:to)
      route(:create, "POST", "/#{base}",
            {:redirect => :show, ValidationError => :new}.merge(params))
    end

    def edit(params={})
      params[:to] = "#{mod}::Record.find_by_id" unless params.key?(:to)
      route(:edit, "GET", "/#{base}/:id/edit", params)
    end

    def update(params={})
      params[:to] = "#{mod}::Record.find_and_update" unless params.key?(:to)
      route(:update, "PUT", "/#{base}/:id",
            {:redirect => :show, ValidationError => :edit}.merge(params))
    end

    def destroy(params={})
      params[:to] = "#{mod}::Record.destroy" unless params.key?(:to)
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
      Raptor::ValidatesRoutes.validate_route_params!(params)
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

    def exception_actions
      @params.select do |maybe_exception, maybe_action|
        maybe_exception.is_a?(Class)
      end
    end

    def responder_for(action)
      redirect = @params[:redirect]
      text = @params[:text]
      if redirect
        RedirectResponder.new(@resource, redirect)
      elsif text
        PlaintextResponder.new(text)
      else
        ActionTemplateResponder.new(@resource, action)
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
    attr_reader :name, :path

    def initialize(name, path, requirements, delegator, responder,
                   exception_actions)
      @name = name
      @path = path
      @requirements = requirements
      @delegator = delegator
      @responder = responder
      @exception_actions = exception_actions
    end

    def self.for_resource(resource, action, http_method, path, params)
      route_options = RouteOptions.new(resource, params)
      requirements = route_options.requirements + [
        HttpMethodRequirement.new(http_method),
        PathRequirement.new(path),
      ]
      delegator = Delegator.new(route_options.delegate_name)
      responder = route_options.responder_for(action)
      new(action, path, requirements, delegator, responder,
          route_options.exception_actions)
    end

    def respond_to_request(request)
      record = @delegator.delegate(request, @path)
      inference = Inference.for_request(request, @path)
      @responder.respond(record, inference)
    end

    def action_for_exception(e)
      @exception_actions.select do |exception_class, action|
        e.is_a? exception_class
      end.values.first
    end

    def match?(request)
      RouteCriteria.new(@path, @requirements).match?(request)
    end
  end

  class RouteCriteria
    def initialize(path, requirements)
      @requirements = requirements
      @path = path
    end

    def match?(request)
      inference_sources = InferenceSources.new(request,
                                               request.path_info).to_hash
      @requirements.all? do |requirement|
        inference = Inference.for_request(request, request.path_info)
        inference.call(requirement.method(:match?))
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
        is_variable = route_component[0] == ':'
        same_components = route_component == path_component
        is_variable || same_components
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

