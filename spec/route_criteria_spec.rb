require './spec/spec_helper'

describe Raptor::RouteCriteria do
  describe "route matching" do
    it "matches if the paths are the same" do
      match?('/post/new', '/post/new').should == true
    end

    it "does not match when the paths are different" do
      match?('/post/new', '/foo/bar').should == false
    end

    it "matches any component when a path has a param" do
      match?('/post/:id', '/post/5').should == true
    end

    it "does not a path with params when the path does not match" do
      match?('/post/:id', '/users/2').should == false
    end

    def match?(route, url)
      Raptor::RouteCriteria.new(route).match?(url)
    end
  end
end


