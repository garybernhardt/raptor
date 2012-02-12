module Raptor
  class Router
    def initialize(app_module, routes)
      @app_module = app_module
      @routes = routes
    end

    def self.build(app_module, &block)
      routes = BuildsRoutes.new(app_module).build(&block)
      new(app_module, routes)
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
      Raptor.log(
        "Routing #{request.path_info.inspect} to #{route.path.inspect}")
    end

    def route_for_request(request)
      @routes.find { |route| route.match?(request) } or raise NoRouteMatches
    end

    def route_named(action_name)
      @routes.find { |route| route.name == action_name }
    end
  end

  class BuildsRoutes
    def initialize(app_module, parent_path="")
      @app_module = app_module
      @parent_path = parent_path
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      @routes
    end

    def path(sub_path_name, &block)
      routes = BuildsRoutes.new(@app_module, "/" + sub_path_name).build(&block)
      routes.each { |route| route.add_neighbors(routes) }
      @routes += routes
    end

    def root(params={})
      route(:root, "GET", "/", params)
    end

    def show(params={})
      params[:to] = "#{record_module}.find_by_id" unless params.key?(:to)
      route(:show, "GET", "/:id",
            {:present => default_single_presenter}.merge(params))
    end

    def new(params={})
      params[:to] = "#{record_module}.new" unless params.key?(:to)
      route(:new, "GET", "/new",
            {:present => default_single_presenter}.merge(params))
    end

    def index(params={})
      params[:to] = "#{record_module}.all" unless params.key?(:to)
      route(:index, "GET", "/",
            {:present => default_list_presenter}.merge(params))
    end

    def create(params={})
      params[:to] = "#{record_module}.create" unless params.key?(:to)
      route(:create, "POST", "/",
            {:redirect => :show, ValidationError => :new}.merge(params))
    end

    def edit(params={})
      params[:to] = "#{record_module}.find_by_id" unless params.key?(:to)
      route(:edit, "GET", "/:id/edit",
            {:present => default_single_presenter}.merge(params))
    end

    def update(params={})
      params[:to] = "#{record_module}.find_and_update" unless params.key?(:to)
      route(:update, "PUT", "/:id",
            {:redirect => :show, ValidationError => :edit}.merge(params))
    end

    def destroy(params={})
      params[:to] = "#{record_module}.destroy" unless params.key?(:to)
      route(:destroy, "DELETE", "/:id",
            {:redirect => :index}.merge(params))
    end

    def last_parent_path_component
      @parent_path.split(/\//).last or raise CantInferModulePathsForRootRoutes
    end

    def default_single_presenter
      Raptor::Util.camel_case(last_parent_path_component)
    end

    def default_list_presenter
      default_single_presenter + "List"
    end

    def record_module
      "Records::#{Raptor::Util.camel_case(last_parent_path_component)}"
    end

    def route(action, http_method, path, params={})
      path = @parent_path + path
      Raptor::ValidatesRoutes.validate_route_params!(params)
      route = Route.for_app_module(@app_module, action, http_method, @parent_path, path, params)
      @routes << route
      route
    end
  end

  class CantInferModulePathsForRootRoutes < RuntimeError; end

  class RouteOptions
    def initialize(app_module, parent_path, params)
      @app_module = app_module
      @parent_path = parent_path
      @params = params
    end

    def delegate_name
      null_delegate = "Raptor::NullDelegate.do_nothing"
      @params.fetch(:to, null_delegate)
    end

    def exception_actions
      @params.select do |maybe_exception, maybe_action|
        maybe_exception.is_a?(Class)
      end
    end

    def responder_for(action)
      redirect = @params[:redirect]
      text = @params[:text]
      presenter = @params[:present].to_s
      template_path = @params[:render]

      if redirect
        RedirectResponder.new(@app_module, redirect)
      elsif text
        PlaintextResponder.new(text)
      elsif template_path
        TemplateResponder.new(@app_module, presenter, template_path)
      else
        ActionTemplateResponder.new(@app_module, presenter, @parent_path, action)
      end
    end

    def requirements
      return [] unless @params.has_key?(:require)
      name = @params.fetch(:require).to_s
      Requirements.new(@app_module).matching(name)
    end
  end

  class Requirements
    def initialize(app_module)
      @app_module = app_module
    end

    def matching(name)
      requirement = @app_module::Requirements.const_get(Util.camel_case(name))
      [requirement]
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

    def add_neighbors(neighbors)
      @neighbors = neighbors
    end

    # XXX: Add proper route tree structure instead of neighbors?
    def neighbor_named(name)
      @neighbors.find { |route| route.name == name }
    end

    def self.for_app_module(app_module, action, http_method, parent_path, path, params)
      route_options = RouteOptions.new(app_module, parent_path, params)
      requirements = route_options.requirements + [
        HttpMethodRequirement.new(http_method),
        PathRequirement.new(path),
      ]
      delegator = Delegator.new(app_module, route_options.delegate_name)
      responder = route_options.responder_for(action)
      new(action, path, requirements, delegator, responder,
          route_options.exception_actions)
    end

    def respond_to_request(request)
      injector = Injector.new.
        add_request(request).
        add_route_path(request, @path)
      record = @delegator.delegate(injector)
      @responder.respond(self, record, injector)
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
      @requirements.all? do |requirement|
        injector = Injector.new.
          add_request(request).
          add_route_path(request, @path)
        injector.call(requirement.method(:match?))
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

  class NullDelegate
    def self.do_nothing
      self
    end
  end
end

