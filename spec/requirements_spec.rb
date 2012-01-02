require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/router"

describe Raptor::HttpMethodRequirement do
  it "matches when the method matches" do
    Raptor::HttpMethodRequirement.new("GET").match?("GET").should be_true
  end

  it "doesn't match when the method doesn't" do
    Raptor::HttpMethodRequirement.new("GET").match?("POST").should be_false
  end
end

describe Raptor::PathRequirement do
  it "matches exact paths" do
    Raptor::PathRequirement.new("/posts").match?("/posts").should be_true
  end

  it "matches variables" do
    Raptor::PathRequirement.new("/posts/:id").match?("/posts/5").should be_true
  end

  it "doesn't match when the paths have different components" do
    Raptor::PathRequirement.new("/posts").match?("/users").should be_false
  end

  it "doesn't match when the route has more components" do
    Raptor::PathRequirement.new("/posts/:id").match?("/posts").should be_false
  end

  it "doesn't match when the route has fewer components" do
    Raptor::PathRequirement.new("/posts").match?("/posts/5").should be_false
  end
end

