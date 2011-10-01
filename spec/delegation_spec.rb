require_relative 'spec_helper'

describe Raptor::DelegateFinder do
  include Raptor

  module AModule
    module Child
      module Grandchild
        def self.a_method
        end
      end
    end
  end

  it "finds constants in the module" do
    method = DelegateFinder.new(AModule, "Child::Grandchild.a_method").find
    method.should == AModule::Child::Grandchild.method(:a_method)
  end

  it "finds constants not in the module" do
    method = DelegateFinder.new(AModule, "Object.new").find
    method.should == Object.method(:new)
  end
end

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

