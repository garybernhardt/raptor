require 'erb'
require 'rack'

class Shorty
  def self.takes(*args)
    @__shorty_args = args
  end

  def self.__shorty_args
    @__shorty_args
  end

  def initialize(*args)
    arg_names = self.class.__shorty_args || []
    arg_names.zip(args).each do |arg_name, arg|
      instance_variable_set(:"@#{arg_name}", arg)
    end
  end

  def self.let(name, &block)
    define_method(name, &block)
  end
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
    ROUTE_CRITERIA = {:show => ["GET", "/%s/:id"],
                      :new => ["GET", "/%s/new"],
                      :index => ["GET", "/%s"],
                      :create => ["POST", "/%s"],
    }

    DEFAULT_DELEGATE_NAMES = {:show => "Record.find_by_id",
                              :new => "Record.new",
                              :index => "Record.all",
                              :create => "Record.create"}

    def initialize(resource, &block)
      @resource = resource
      @routes = []
      instance_eval(&block)
    end

    def call(request)
      route = route_for_request(request)
      Raptor.log %{#{@resource.resource_name} routing #{request.path_info.inspect} to #{route.path.inspect}} # XXX: path abstraction
      route.call(request)
    end

    def route_for_request(request)
      @routes.find {|r| r.match?(request) } or raise NoRouteMatches
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

  class Route
    attr_reader :path

    def initialize(path, criteria, delegate_name, template_name, resource)
      @path = path
      @criteria = criteria
      @delegate_name = delegate_name
      @template_name = template_name
      @resource = resource
    end

    def call(request)
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

    def match?(request)
      @criteria.match?(request.request_method, request.path_info)
    end

    def render(presenter)
      Template.new(presenter, @resource.path_component, @template_name).render
    end
  end

  class Delegator < Shorty
    takes :request, :route_path, :resource, :delegate_name

    let(:delegate_method) { @resource.record_class.method(method_name) }
    let(:method_name) { @delegate_name.split('.').last.to_sym }

    def delegate
      delegate_method.call(*delegate_args)
    end

    def delegate_args
      inference_sources = InferenceSources.new(@request,
                                               @route_path,
                                               @request.path_info).sources
      InfersArgs.new(delegate_method, inference_sources).args
    end
  end

  class Template < Shorty
    takes :presenter, :resource_name, :name

    let(:template) { ERB.new(File.new(template_path).read) }
    let(:template_path) { "views/#{@resource_name}/#{@name}.html.erb" }

    def render
      template.result(@presenter.instance_eval { binding })
    end
  end

  class InferenceSources < Shorty
    takes(:request, :route_path, :path)

    let(:sources)  { {:params => @request.params}.merge(extract_args) }
    let(:path_component_pairs) { @route_path.split('/').zip(@path.split('/')) }

    def extract_args
      args = {}
      path_component_pairs.select do |route_component, path_component|
        route_component[0] == ':'
      end.each do |x, y|
        args[x[1..-1].to_sym] = y.to_i
      end
      args
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

  class Resource < Shorty
    def self.wrap(resource)
      new(resource)
    end

    takes :resource

    let(:path_component) { underscore(resource_name) }
    let(:resource_name) { @resource.name.split('::').last }
    let(:record_class) { @resource.const_get(:Record) }
    let(:one_presenter) { @resource.const_get(:PresentsOne) }
    let(:many_presenter) { @resource.const_get(:PresentsMany) }

    def underscore(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end
  end

  class RouteCriteria < Shorty
    attr_reader :path
    takes :http_method, :path

    let(:components) { @path.split('/') }

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
  end

  def self.log(text)
    puts "Raptor: #{text}" if ENV['RAPTOR_LOGGING']
  end
end

