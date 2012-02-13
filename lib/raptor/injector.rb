module Raptor
  class Injector
    def initialize(injectables=[])
      @injectables = injectables
    end

    def sources
      # Merge all injectables' sources into a single hash
      @sources ||= @injectables.map do |injectable|
        injectable.sources(self)
      end.inject(&:merge)
    end

    def call(method)
      args = self.args(method)
      Raptor.log("Injecting #{method.inspect} with #{args.inspect}")
      method.call(*args)
    end

    def args(method)
      method = injection_method(method)
      parameters(method).select do |type, name|
        name && type != :rest && type != :block
      end.map do |type, name|
        source_proc = sources[name] or raise UnknownInjectable.new(name)
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
      Injector.new(@injectables +
                   [Raptor::Injectables::Fixed.new(:record, record)])
    end

    def add_request(request)
      injectables = @injectables + [Injectables::Request.new(request)]
      Injector.new(injectables)
    end

    def add_route_path(request, route_path)
      injectables = @injectables + [Injectables::RouteVariable.new(request,
                                                                   route_path)]
      Injector.new(injectables)
    end
  end

  class UnknownInjectable < RuntimeError
    def initialize(name)
      super("Unknown injectable name: #{name.inspect}")
    end
  end

  module Injectables
    class All
      def initialize(app_module, request, route_path)
        @custom_injectable = Custom.new(app_module)
        @injectables = [Request.new(request),
                        RouteVariable.new(request, route_path)]
      end

      def sources(injector)
        injectables = @injectables + @custom_injectable.injectables(injector)
        injectables.map do |injectable|
          injectable.sources(injector)
        end.inject(&:merge)
      end
    end

    class Custom
      def initialize(app_module)
        @app_module = app_module
      end

      def injectables(injector)
        injectables_module = @app_module::Injectables
        injectables_module.constants.map do |const_name|
          injectables_module.const_get(const_name)
        end.select do |const|
          const.is_a?(Class)
        end.map do |const|
          injector.call(const.method(:new))
        end
      end
    end

    class Request
      def initialize(request)
        @request = request
      end

      def sources(injector)
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

      def sources(injector)
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

    class Fixed
      def initialize(name, value)
        @name, @value = name, value
      end

      def sources(injector)
        {@name => lambda { @value } }
      end
    end
  end
end

