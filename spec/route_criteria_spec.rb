require './spec/spec_helper'

describe Raptor::RouteCriteria do
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
      Raptor::RouteCriteria.new(route, []).match?(url, {})
    end
  end

  describe "requirement matching" do
    it "matches if the requirement matches" do
      match?(stub(:match? => true)).should be_true
    end

    it "doesn't match if the requirement doesn't" do
      match?(stub(:match? => false)).should be_false
    end

    def match?(requirement)
      criteria = Raptor::RouteCriteria.new("/url", [requirement])
      criteria.match?("/url", {})
    end
  end

  describe "argument inference" do
    it "infers requirement arguments" do
      requirement = Module.new do
        def self.match?(path)
          path == "/the/path"
        end
      end
      inference_sources = {:path => "/the/path"}
      criteria = Raptor::RouteCriteria.new("/url", [requirement])
      criteria.match?("/url", inference_sources).should be_true
    end
  end
end

