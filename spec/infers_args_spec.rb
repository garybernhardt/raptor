require './spec/spec_helper'
require 'mocha'

describe Raptor::InfersArgs do
  def method_taking_id(id); end
  def method_taking_params(params); end
  def method_taking_splat(*); end
  def method_taking_nothing; end

  before do
    @request = Rack::Request.new('PATH_INFO' => '/post/5', 'rack.input' => '')
    @path = stub(:extract_args => {:id => 5})
  end

  def infer(method_name)
    Raptor::InfersArgs.for(@request, method(method_name), @path)
  end

  it "infers required arguments for delegate methods" do
    infer(:method_taking_id).must_equal [5]
  end

  it "infers :params" do
    infer(:method_taking_params).must_equal [@request.params]
  end

  it "infers [] when the method only takes optional parameters" do
    infer(:method_taking_splat).must_equal []
  end

  it "infers [] when the method takes nothing" do
    infer(:method_taking_nothing).must_equal []
  end
end

