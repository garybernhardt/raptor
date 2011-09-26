require './spec/spec_helper'

describe Raptor::RoutePath do
  describe "route matching" do
    it "matches if the paths are the same" do
      matches?('/post/new', '/post/new').must_equal true
    end

    it "does not match when the paths are different" do
      matches?('/post/new', '/foo/bar').must_equal false
    end

    it "matches any component when a path has a param" do
      matches?('/post/:id', '/post/5').must_equal true
    end

    it "does not a path with params when the path does not match" do
      matches?('/post/:id', '/users/2').must_equal false
    end

    def matches?(route, url)
      Raptor::RoutePath.new(route).matches?(url)
    end
  end
end


