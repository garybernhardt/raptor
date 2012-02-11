require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/injector"

describe Raptor::Injector do

  def method_taking_id(id); id; end
  def method_taking_params(params); params; end
  def method_taking_splat(*); 'nothing'; end
  def method_taking_nothing; 'nothing' end
  def method_taking_only_a_block(&block); 'nothing' end
  def method_taking_record(record); record; end

  let(:params) { stub }
  let(:sources) do
    {:params => lambda { params }, :id => lambda { 5 } }
  end
  let(:injector) { Raptor::Injector.new(sources) }

  it "injects required arguments for delegate methods" do
    injector.call(method(:method_taking_id)).should == 5
  end

  it "injects :params" do
    injector.call(method(:method_taking_params)).should == params
  end

  it "injects [] when the method only takes optional parameters" do
    injector.call(method(:method_taking_splat)).should == 'nothing'
  end

  it "injects [] when the method takes nothing" do
    injector.call(method(:method_taking_nothing)).should == 'nothing'
  end

  it "injects [] when the method takes only a block" do
    injector.call(method(:method_taking_only_a_block)).should == 'nothing'
  end

  it "injects arguments from initialize for the new method" do
    method = ObjectWithInitializerTakingParams.method(:new)
    injector.call(method).params.should == params
  end

  it "injects records once it's been given one" do
    record = stub
    method = method(:method_taking_record)
    injector_with_record = injector.add_record(record)
    injector_with_record.call(method).should == record
  end

  it "throws an error when no source is found for an argument" do
    klass = Class.new { def f(unknown_argument); end }
    expect do
      injector.call(klass.new.method(:f))
    end.to raise_error(Raptor::Injector::UnknownInjectable)
  end
end

class ObjectWithInitializerTakingParams
  attr_reader :params
  def initialize(params)
    @params = params
  end
end

