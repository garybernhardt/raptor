require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/delegation"
require_relative "../lib/raptor/injector"

describe Raptor::DelegateFinder do
  include Raptor

  module AModule
    module Child
      def self.a_method
      end
    end
  end

  it "finds constants in the module" do
    method = DelegateFinder.new("AModule::Child.a_method").find
    method.should == AModule::Child.method(:a_method)
  end

  it "finds constants not in the module" do
    method = DelegateFinder.new("Object.new").find
    method.should == Object.method(:new)
  end
end

describe Raptor::Delegator do
  it "returns nil if the delegate is nil" do
    Raptor::InjectionSources.stub(:new) { stub(:to_hash => {}) }
    request = stub("request")
    route_path = "/my_resource"
    delegator = Raptor::Delegator.new(nil)
    delegator.delegate(request, route_path).should be_nil
  end
end

