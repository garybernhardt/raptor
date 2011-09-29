module Raptor
  class Router
    def initialize(resource, &block)
      @resource = resource
      @routes = BuildsRoutes.new(resource).build(&block)
    end

    def call(request)
      route = route_for_request(request)
      log_routing_of(route, request)
      begin
        route.respond_to_request(request)
      rescue Exception => e
        Raptor.log("Looking for a redirect for #{e.inspect}")
        handle_exception(request, route.redirects, e) or raise
      end
    end

    def handle_exception(request, redirects, e)
      redirects.each_pair do |maybe_exception, maybe_action|
        if maybe_exception.is_a?(Class) && e.is_a?(maybe_exception)
          return route_named(maybe_action).respond_to_request(request)
        end
      end
      false
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
            :redirect => :show, ValidationError => :new)
    end

    def edit(delegate_name="Record.find_by_id")
      route(:edit, "GET", "/#{base}/:id/edit", delegate_name)
    end

    def update(delegate_name="Record.find_and_update")
      route(:update, "PUT", "/#{base}/:id", delegate_name,
            :redirect => :show, ValidationError => :edit)
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
      @routes << Route.new(action, criteria, delegator, responder, redirects)
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
end

