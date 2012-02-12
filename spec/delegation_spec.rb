require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/delegation"
require_relative "../lib/raptor/injector"

describe Raptor::DelegateFinder do
  module AModule
    module Child
      def self.a_method
      end
    end
  end

  it "finds constants in the module" do
    method = Raptor::DelegateFinder.new(AModule, "Child.a_method").find
    method.should == AModule::Child.method(:a_method)
  end

  it "finds constants not in the module" do
    method = Raptor::DelegateFinder.new(AModule, "Object.new").find
    method.should == Object.method(:new)
  end
end

describe Raptor::Delegator do
  it "returns nil if the delegate is nil" do
    Raptor::Injectables::All.stub(:new) { stub(:sources => {}) }
    request = stub("request")
    route_path = "/my_resource"
    delegator = Raptor::Delegator.new(AModule, nil)
    delegator.delegate(request, route_path).should be_nil
  end

  it "calls the named method" do
    delegator = Raptor::Delegator.new(Object, "Hash.new")
    request = stub(:request).as_null_object
    route_path = stub(:route_path).as_null_object
    injector = Raptor::Injector.new({})
    Raptor::Injector.stub(:for_request).with(request, route_path) { injector }
    delegator.delegate(request, route_path).should == {}
  end
end

