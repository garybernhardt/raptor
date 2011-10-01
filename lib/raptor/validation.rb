module Raptor
  class ConflictingRoutes < RuntimeError; end
  class ValidatesRoutes
    def self.validate!(routes)
      raise Raptor::ConflictingRoutes if pairs(routes).any? do |a, b|
        same_names?(a,b) && same_redirects?(a,b)
      end
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
end

