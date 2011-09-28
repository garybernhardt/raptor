require './spec/spec_helper'

describe Raptor::InfersArgs do
  def method_taking_id(id); end
  def method_taking_params(params); end
  def method_taking_splat(*); end
  def method_taking_nothing; end
  def method_taking_only_a_block(&block); end

  before do
    @params = stub
    @sources = {:params => @params,
                :id => 5}
  end

  def infer(method_name)
    Raptor::InfersArgs.new(method(method_name), @sources).args
  end

  it "infers required arguments for delegate methods" do
    infer(:method_taking_id).should == [5]
  end

  it "infers :params" do
    infer(:method_taking_params).should == [@params]
  end

  it "infers [] when the method only takes optional parameters" do
    infer(:method_taking_splat).should == []
  end

  it "infers [] when the method takes nothing" do
    infer(:method_taking_nothing).should == []
  end

  it "infers [] when the method takes only a block" do
    infer(:method_taking_only_a_block).should == []
  end
end

