module Raptor
  class Delegator
    def initialize(resource, delegate_name)
      @resource = resource
      @delegate_name = delegate_name
    end

    def delegate(request, route_path)
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
      domain_class.method(method_name)
    end

    def domain_class
      @resource.class_named(delegate_class_name)
    end

    def delegate_class_name
      @delegate_name.split('.').first.split('::').last
    end

    def method_name
      @delegate_name.split('.').last.to_sym
    end

    def inference_sources(request, route_path)
      InferenceSources.new(request, route_path).to_hash
    end
  end
end

