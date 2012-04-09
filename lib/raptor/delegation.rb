module Raptor
  class DelegateFinder
    def initialize(starting_module, delegate_name)
      @starting_module = starting_module
      @module_path, @method_name = delegate_name.split('.')
    end

    def find
      target_module.method(@method_name)
    end

    def target_module
      the_module = @starting_module
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
    def initialize(app, delegate_path)
      @app = app
      @delegate_path = delegate_path
    end

    def delegate(injector)
      return nil if @delegate_path.nil?
      Raptor.log("Delegating to #{@delegate_path.inspect}")
      subject = injector.call(delegate_method)
      Raptor.log("Delegate returned #{subject.inspect}")
      subject
    end

    def delegate_method
      @app.find_method(@delegate_path)
    end
  end
end

