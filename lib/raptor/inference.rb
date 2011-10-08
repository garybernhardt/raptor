module Raptor
  # XXX: Inference should call the method with the args so the caller doesn't
  # have to
  class Inference
    def initialize(sources)
      @sources = sources
    end

    def self.for_request(request, route_path)
      sources = InferenceSources.new(request, route_path).to_hash
      new(sources)
    end

    def call(method)
      method.call(*args(method))
    end

    def args(method)
      method = method_for_inference(method)
      parameters(method).select do |type, name|
        name && type != :rest && type != :block
      end.map do |type, name|
        @sources.fetch(name)
      end
    end

    def parameters(method)
      method.parameters
    end

    def method_for_inference(method)
      if method.name == :new
        method.receiver.instance_method(:initialize)
      else
        method
      end
    end

    def add_record(record)
      sources = @sources.merge(:record => record)
      Inference.new(sources)
    end
  end

  class InferenceSources
    def initialize(request, route_path)
      @request = request
      @route_path = route_path
    end

    def to_hash
      request_sources.merge(path_arg_sources)
    end

    def request_sources
      {:path => @request.path_info,
       :params => @request.params,
       :http_method => @request.request_method,
       :request => @request}
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
  end
end

