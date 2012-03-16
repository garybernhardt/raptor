module Raptor
  class Injector
    def initialize(injectables=[])
      @injectables = injectables
    end

    def self.for_app(app)
      Injector.new([CustomInjectable.new(app)])
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

    def add_subject(subject)
      Injector.new(@injectables +
                   [Raptor::Injectables::Fixed.new(:subject, subject)])
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

  class CustomInjectable
    def initialize(app)
      @app = app
    end

    def sources(injector)
      injectables(injector).map do |injectable|
        injectable.sources(injector)
      end.inject(&:merge) || {}
    end

    def injectables(injector)
      @app.injectables.map do |const|
        injector.call(const.method(:new))
      end
    end
  end

  module Injectables
    class Request
      def initialize(request)
        @request = request
      end

      def sources(injector)
        {:rack_request => lambda { @request },
         :http_method => lambda { @request.request_method },
         :path => lambda { @request.path_info },
         :params => lambda { @request.params },
         :rack_env => lambda { @request.env }
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

