require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

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
    injector = Raptor::Injector.new([])
    delegator = Raptor::Delegator.new(AModule, nil)
    delegator.delegate(injector).should be_nil
  end

  it "calls the named method" do
    delegator = Raptor::Delegator.new(Object, "Hash.new")
    injector = Raptor::Injector.new([])
    delegator.delegate(injector).should == {}
  end
end

