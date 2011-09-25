require './spec/spec_helper'
require 'mocha'

describe Raptor::InfersArgs do
  def method_taking_id(id); end
  def method_taking_params(params); end
  def method_taking_splat(*); end
  def method_taking_nothing; end

  before do
    @request = stub(:path_info => '/post/5', :params => stub)
  end

  it "infers required arguments for delegate methods" do
    Raptor::InfersArgs.for(@request,
                           method(:method_taking_id),
                           stub(:extract_args => {:id => 5})).must_equal [5]
  end

  it "infers :params" do
    Raptor::InfersArgs.for(@request,
                           method(:method_taking_params),
                           stub(:extract_args => {})).must_equal [@request.params]
  end

  it "infers [] when the method only takes optional parameters" do
    Raptor::InfersArgs.for(@request,
                           method(:method_taking_splat),
                           stub).must_equal []
  end

  it "infers [] when the method takes nothing" do
    Raptor::InfersArgs.for(@request,
                           method(:method_taking_nothing),
                           stub).must_equal []
  end
end

