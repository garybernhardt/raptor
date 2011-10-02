module Raptor
  class DelegateFinder
    def initialize(delegate_name)
      @module_path, @method_name = delegate_name.split('.')
    end

    def find
      target_module.method(@method_name)
    end

    def target_module
      the_module = Object
      module_path_components.each do |module_name|
        the_module = the_module.const_get(module_name)
      end
      the_module
    end

    def module_path_components
      @module_path.split('::')
    end
  end

  class Delegator
    def initialize(delegate_name)
      @delegate_name = delegate_name
    end

    def delegate(request, route_path)
      return nil if @delegate_name.nil?
      Raptor.log("Delegating to #{@delegate_name}")
      sources = inference_sources(request, route_path)
      record = delegate_method.call(*delegate_args(sources))
      Raptor.log("Delegate returned #{record}")
      record
    end

    def delegate_args(sources)
      InfersArgs.new(delegate_method, sources).args
    end

    def delegate_method
      DelegateFinder.new(@delegate_name).find
    end

    def inference_sources(request, route_path)
      InferenceSources.new(request, route_path).to_hash
    end
  end
end

