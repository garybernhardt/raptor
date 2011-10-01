require_relative 'spec_helper'

describe Raptor::Delegator do
  it "returns nil if the delegate is nil" do
    Raptor::InferenceSources.stub(:new) { stub(:to_hash => {}) }
    resource = stub("resource")
    request = stub("request")
    route_path = "/my_resource"
    delegator = Raptor::Delegator.new(resource, nil)
    delegator.delegate(request, route_path).should be_nil
  end
end

