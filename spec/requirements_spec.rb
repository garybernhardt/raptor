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

