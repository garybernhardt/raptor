module Raptor
  class ValidatesRoutes
    def self.validate_route_params!(params)
      raise Raptor::ConflictingRoutes if params[:redirect] && params[:render]
      if bad_delegate?(params[:to])
        raise Raptor::BadDelegate.new("#{params[:to]} is not a good delegate name")
      end
    end

    def self.pairs(routes)
      routes.product(routes).select do |x,y|
        x != y
      end
    end

    def self.bad_delegate?(delegate_name)
      return false if delegate_name.nil?
      ['#','.'].select do |method_splitter|
        delegate_name.include?(method_splitter)
      end.empty?
    end

    def self.same_names?(a,b)
      a.name == b.name
    end

    def self.same_redirects?(a,b)
      a.redirects == b.redirects
    end

  end

  class ConflictingRoutes < RuntimeError; end
  class BadDelegate < RuntimeError; end
end

