module Raptor
  class Router
    def initialize(app, routes)
      @app = app
      @routes = routes
    end

    def self.build(app, &block)
      routes = BuildsRoutes.new(app).build(&block)
      new(app, routes)
    end

    def call(env)
      request = Rack::Request.new(env)
      Raptor.log "App: routing #{request.request_method} #{request.path_info}"
      injector = Injector.for_app(@app).add_request(request)
      begin
        route = route_for_request(injector, request)
      rescue NoRouteMatches
        Raptor.log("No route matches")
        return Rack::Response.new("", 404)
      end

      begin
        route.respond_to_request(injector, request)
      rescue Exception => e
        Raptor.log("Looking for a redirect for #{e.inspect}")
        injector = injector.add_exception(e)
        action = route.action_for_exception(e) or raise
        route_named(action).respond_to_request(injector, request)
      end
    end

    def route_for_request(injector, request)
      @routes.find { |route| route.match?(injector, request) } or
        raise NoRouteMatches
    end

    def route_named(action_name)
      @routes.find { |route| route.name == action_name }
    end
  end

  module StandardRoutes
    def root(params={})
      route(:root, "GET", "/", params)
    end

    def show(params={})
      route(:show, "GET", "/:id",
            {:present => default_single_presenter,
             :to => "#{record_module}.find_by_id"}.merge(params))
    end

    def new(params={})
      route(:new, "GET", "/new",
            {:present => default_single_presenter,
             :to => "#{record_module}.new"}.merge(params))
    end

    def index(params={})
      route(:index, "GET", "/",
            {:present => default_list_presenter,
             :to => "#{record_module}.all"}.merge(params))
    end

    def create(params={})
      route(:create, "POST", "/",
            {:redirect => :show,
             ValidationError => :new,
             :to => "#{record_module}.create"}.merge(params))
    end

    def edit(params={})
      route(:edit, "GET", "/:id/edit",
            {:present => default_single_presenter,
             :to => "#{record_module}.find_by_id"}.merge(params))
    end

    def update(params={})
      route(:update, "PUT", "/:id",
            {:redirect => :show,
             ValidationError => :edit,
             :to => "#{record_module}.find_and_update"}.merge(params))
    end

    def destroy(params={})
      route(:destroy, "DELETE", "/:id",
            {:redirect => :index,
             :to => "#{record_module}.destroy"}.merge(params))
    end
  end

  class BuildsRoutes
    include StandardRoutes

    def initialize(app, parent_path="")
      @app = app
      @parent_path = parent_path
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      @routes
    end

    def path(sub_path_name, &block)
      routes = BuildsRoutes.new(@app, "/" + sub_path_name).build(&block)
      routes.each { |route| route.add_neighbors(routes) }
      @routes += routes
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
      params = params.merge(:action => action,
                            :http_method => http_method,
                            :path => path)
      route = Route.for_app(@app, @parent_path, params)
      @routes << route
      route
    end
  end

  class CantInferModulePathsForRootRoutes < RuntimeError; end

  class RouteOptions
    NULL_DELEGATE_NAME = "Raptor::NullDelegate.do_nothing"

    def initialize(app, parent_path, params)
      @app = app
      @parent_path = parent_path
      @params = params
    end

    def action; @params.fetch(:action); end
    def http_method; @params.fetch(:http_method); end
    def path; @params.fetch(:path); end

    def delegator
      delegate_name = @params.fetch(:to, NULL_DELEGATE_NAME)
      Raptor::Delegator.new(@app, delegate_name)
    end

    def exception_actions
      @params.select do |maybe_exception, maybe_action|
        maybe_exception.is_a?(Class)
      end
    end

    def responder
      redirect = @params[:redirect]
      text = @params[:text]
      presenter = @params[:present].to_s
      template_path = @params[:render]

      if redirect.is_a?(String)
        RedirectResponder.new(redirect)
      elsif redirect
        ActionRedirectResponder.new(@app, redirect)
      elsif text
        PlaintextResponder.new(text)
      elsif template_path
        TemplateResponder.new(@app, presenter, template_path, path)
      else
        TemplateResponder.action_template(@app, presenter, @parent_path, action)
      end
    end

    def constraints
      standard_constraints + custom_constraints
    end

    def standard_constraints
      [HttpMethodConstraint.new(http_method),
       PathConstraint.new(path)]
    end

    def custom_constraints
      return [] unless @params.has_key?(:if)
      name = @params.fetch(:if).to_s
      Constraints.new(@app).matching(name)
    end
  end

  class Constraints
    def initialize(app)
      @app = app
    end

    def matching(name)
      constraint = @app.constraint_named(Util.camel_case(name))
      [constraint.new]
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    attr_reader :name, :path

    def initialize(name, path, constraints, delegator, responder,
                   exception_actions)
      @name = name
      @path = path
      @constraints = constraints
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

    def self.for_app(app, parent_path, params)
      options = RouteOptions.new(app, parent_path, params)
      new(options.action,
          options.path,
          options.constraints,
          options.delegator,
          options.responder,
          options.exception_actions)
    end

    def respond_to_request(injector, request)
      Raptor.log("Routing #{request.path_info.inspect} to #{path.inspect}")
      injector = injector.add_route_path(request, @path)
      subject = @delegator.delegate(injector)
      @responder.respond(self, subject, injector)
    end

    def action_for_exception(e)
      @exception_actions.select do |exception_class, action|
        e.is_a? exception_class
      end.values.first
    end

    def match?(injector, request)
      injector = injector.add_route_path(request, @path)
      @constraints.all? do |constraint|
        injector.call(constraint.method(:match?))
      end
    end
  end

  class HttpMethodConstraint
    def initialize(http_method)
      @http_method = http_method
    end

    def match?(http_method)
      http_method == @http_method
    end
  end

  class PathConstraint
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
      nil
    end
  end
end

