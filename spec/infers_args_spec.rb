require './spec/spec_helper'
require 'mocha'

describe Raptor::InfersArgs do
  it "infers required arguments for delegate methods" do
    Raptor::InfersArgs.for(stub(:path_info => 'post/5', :params => stub),
                           stub(:name => :a_method, :parameters => [[:req, :id]]),
                           stub(:extract_args => {:id => 5})).must_equal [5]
  end

  it "infers :params" do
    params = {'params' => 'hash'}
    Raptor::InfersArgs.for(stub(:path_info => 'post/new', :params => params),
                           stub(:name => :a_method, :parameters => [[:req, :params]]),
                           stub(:extract_args => {})).must_equal [params]
  end

  it "infers [] when the method only takes optional parameters" do
    Raptor::InfersArgs.for(stub,
                           stub(:name => :a_method, :parameters => [[:rest]]),
                           stub).must_equal []
  end
end


