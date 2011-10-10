module Raptor
  class ValidatesRoutes
    def self.validate_route_params!(params)
      raise Raptor::ConflictingRoutes if params[:redirect] && params[:render]
    end

    def self.pairs(routes)
      routes.product(routes).select do |x,y|
        x != y
      end
    end

    def self.same_names?(a,b)
      a.name == b.name
    end

    def self.same_redirects?(a,b)
      a.redirects == b.redirects
    end

  end

  class ConflictingRoutes < RuntimeError; end
end

