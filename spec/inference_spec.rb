require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/inference"

describe Raptor::Inference do
  include Raptor

  def method_taking_id(id); id; end
  def method_taking_params(params); params; end
  def method_taking_splat(*); 'nothing'; end
  def method_taking_nothing; 'nothing' end
  def method_taking_only_a_block(&block); 'nothing' end
  def method_taking_record(record); record; end

  let(:params) { stub }
  let(:sources) { {:params => params, :id => 5} }
  let(:inference) { Inference.new(sources) }

  it "infers required arguments for delegate methods" do
    inference.call(method(:method_taking_id)).should == 5
  end

  it "infers :params" do
    inference.call(method(:method_taking_params)).should == params
  end

  it "infers [] when the method only takes optional parameters" do
    inference.call(method(:method_taking_splat)).should == 'nothing'
  end

  it "infers [] when the method takes nothing" do
    inference.call(method(:method_taking_nothing)).should == 'nothing'
  end

  it "infers [] when the method takes only a block" do
    inference.call(method(:method_taking_only_a_block)).should == 'nothing'
  end

  it "infers arguments from initialize for the new method" do
    method = ObjectWithInitializerTakingParams.method(:new)
    inference.call(method).params.should == params
  end

  it "infers records once it's been given one" do
    record = stub
    method = method(:method_taking_record)
    inference_with_record = inference.add_record(record)
    inference_with_record.call(method).should == record
  end
end

class ObjectWithInitializerTakingParams
  attr_reader :params
  def initialize(params)
    @params = params
  end
end

