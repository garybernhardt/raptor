module Raptor
  # XXX: InfersArgs should call the method with the args so the caller doesn't
  # have to
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

  class InferenceSources
    def initialize(request, route_path, record=nil)
      @request = request
      @route_path = route_path
      @record = record
    end

    def to_hash
      request_sources.merge(path_arg_sources).merge(record_sources)
    end

    def request_sources
      {:path => @request.path_info,
       :params => @request.params,
       :http_method => @request.request_method}
    end

    def path_arg_sources
      args = {}
      path_component_pairs.select do |route_component, path_component|
        route_component[0] == ':'
      end.each do |x, y|
        args[x[1..-1].to_sym] = y.to_i
      end
      args
    end

    def path_component_pairs
      @route_path.split('/').zip(@request.path_info.split('/'))
    end

    def record_sources
      @record ? {:record => @record} : {}
    end

    def with_record(record)
      InferenceSources.new(@request, @route_path, record)
    end
  end
end

