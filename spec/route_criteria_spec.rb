require './spec/spec_helper'

describe Raptor::RouteCriteria do
  describe "http method matching" do
    it "matches if the methods are the same" do
      match?('GET', 'GET').should == true
    end

    it "doesn't match if the methods are different" do
      match?('GET', 'PUT').should == false
    end

    def match?(method1, method2)
      Raptor::RouteCriteria.new(method1, '/path').match?(method2, '/path')
    end
  end

  describe "path matching" do
    it "matches if the paths are the same" do
      match?('/post/new', '/post/new').should == true
    end

    it "doesn't match when the paths are different" do
      match?('/post/new', '/foo/bar').should == false
    end

    it "matches any component when a path has a param" do
      match?('/post/:id', '/post/5').should == true
    end

    it "doesn't match a path with params when the path doesn't match" do
      match?('/post/:id', '/users/2').should == false
    end

    it "doesn't match a path with extra components" do
      match?('/posts', '/posts/new').should == false
      match?('/posts/new', '/posts').should == false
    end

    def match?(route, url)
      Raptor::RouteCriteria.new('GET', route).match?('GET', url)
    end
  end
end

