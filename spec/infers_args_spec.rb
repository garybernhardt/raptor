require './spec/spec_helper'

describe Raptor::InfersArgs do
  it "infers for required params for delegate methods" do
    Raptor::InfersArgs.for(stub(:path_info => 'posts/5'), stub(:parameters => [[:req, :id]]), stub(:extract_args => {:id => 5})).must_equal [5]
  end

  it "infers [] when the method only takes optional parameters" do
    Raptor::InfersArgs.for(stub, stub(:parameters => [[:rest]]), stub).must_equal []
  end
end


