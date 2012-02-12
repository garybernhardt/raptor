module Raptor
  class Injector
    class UnknownInjectable < RuntimeError
      def initialize(name)
        super("Unknown injectable name: #{name.inspect}")
      end
    end

    def initialize(sources={})
      @sources = sources
    end

    def call(method)
      method.call(*args(method))
    end

    def args(method)
      method = injection_method(method)
      parameters(method).select do |type, name|
        name && type != :rest && type != :block
      end.map do |type, name|
        source_proc = @sources[name] or raise UnknownInjectable.new(name)
        source_proc.call
      end
    end

    def parameters(method)
      method.parameters
    end

    def injection_method(method)
      if method.name == :new
        method.receiver.instance_method(:initialize)
      else
        method
      end
    end

    def add_record(record)
      sources = @sources.merge(:record => lambda { record })
      Injector.new(sources)
    end

    def add_request(request)
      sources = @sources.merge(Injectables::Request.new(request).sources)
      Injector.new(sources)
    end

    def add_route_path(request, route_path)
      sources = @sources.merge(
        Injectables::RouteVariable.new(request, route_path).sources)
      Injector.new(sources)
    end
  end

  module Injectables
    class Request
      def initialize(request)
        @request = request
      end

      def sources
        {:request => lambda { @request },
         :http_method => lambda { @request.request_method },
         :path => lambda { @request.path_info },
         :params => lambda { @request.params }
        }
      end
    end

    class RouteVariable
      def initialize(request, route_path)
        @request = request
        @route_path = route_path
      end

      def sources
        Hash[path_component_pairs.map do |name, value|
          [name, lambda { value }]
        end]
      end

      def path_component_pairs
        all_pairs = @route_path.split('/').zip(@request.path_info.split('/'))
        variable_pairs = all_pairs.select do |name, value|
          name =~ /^:/
        end
        variable_pairs_without_colons = variable_pairs.map do |name, value|
          [name.sub(/^:/, "").to_sym, value]
        end
        variable_pairs_without_colons
      end
    end
  end
end

