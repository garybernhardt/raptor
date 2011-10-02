require './spec/spec_helper'

describe Raptor::InfersArgs do
  def method_taking_id(id); id; end
  def method_taking_params(params); params; end
  def method_taking_splat(*); 'nothing'; end
  def method_taking_nothing; 'nothing' end
  def method_taking_only_a_block(&block); 'nothing' end

  let(:params) { stub }
  let(:sources) { {:params => params, :id => 5} }

  def infer(method_name)
    Raptor::InfersArgs.new(method(method_name), sources).call
  end

  it "infers required arguments for delegate methods" do
    infer(:method_taking_id).should == 5
  end

  it "infers :params" do
    infer(:method_taking_params).should == params
  end

  it "infers [] when the method only takes optional parameters" do
    infer(:method_taking_splat).should == 'nothing'
  end

  it "infers [] when the method takes nothing" do
    infer(:method_taking_nothing).should == 'nothing'
  end

  it "infers [] when the method takes only a block" do
    infer(:method_taking_only_a_block).should == 'nothing'
  end
end

