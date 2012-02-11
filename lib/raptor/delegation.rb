module Raptor
  class DelegateFinder
    def initialize(app_module, delegate_name)
      @app_module = app_module
      @module_path, @method_name = delegate_name.split('.')
    end

    def find
      target_module.method(@method_name)
    end

    def target_module
      the_module = @app_module
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
    def initialize(app_module, delegate_name)
      @app_module = app_module
      @delegate_name = delegate_name
    end

    def delegate(request, route_path)
      return nil if @delegate_name.nil?
      Raptor.log("Delegating to #{@delegate_name.inspect}")
      injector = injector(request, route_path)
      record = injector.call(delegate_method)
      Raptor.log("Delegate returned #{record.inspect}")
      record
    end

    def delegate_method
      DelegateFinder.new(@app_module, @delegate_name).find
    end

    def injector(request, route_path)
      Injector.for_request(request, route_path)
    end
  end
end

