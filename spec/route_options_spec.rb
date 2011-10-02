require_relative "../lib/raptor/router"

describe Raptor::RouteOptions do
  include Raptor

  it "knows actions for exceptions" do
    options = RouteOptions.new(stub('resource'),
                               :redirect => :show,
                               IndexError => :index)
    options.exception_actions.should == {IndexError => :index}
  end
end

