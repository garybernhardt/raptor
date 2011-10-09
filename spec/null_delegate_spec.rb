require "rack"
require_relative "../lib/raptor/router"

describe Raptor::NullDelegate do
  it "does nothing" do
    Raptor::NullDelegate.do_nothing.should == Raptor::NullDelegate
  end
end

