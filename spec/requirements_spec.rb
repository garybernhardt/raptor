require "raptor/router"

describe Raptor::HttpMethodRequirement do
  include Raptor

  it "matches when the method matches" do
    HttpMethodRequirement.new("GET").match?("GET").should be_true
  end

  it "doesn't match when the method doesn't" do
    HttpMethodRequirement.new("GET").match?("POST").should be_false
  end
end

describe Raptor::PathRequirement do
  include Raptor

  it "matches exact paths" do
    PathRequirement.new("/posts").match?("/posts").should be_true
  end

  it "matches variables" do
    PathRequirement.new("/posts/:id").match?("/posts/5").should be_true
  end

  it "doesn't match when the paths have different components" do
    PathRequirement.new("/posts").match?("/users").should be_false
  end

  it "doesn't match when the route has more components" do
    PathRequirement.new("/posts/:id").match?("/posts").should be_false
  end

  it "doesn't match when the route has fewer components" do
    PathRequirement.new("/posts").match?("/posts/5").should be_false
  end
end

