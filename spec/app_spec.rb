require './spec/spec_helper'

describe Raptor::App do
  def app
    Raptor::App.new([FakeResources::Post, FakeResources::WithNoBehavior])
  end

  it "routes to multiple resources" do
    request = request('/post/5')
    app.call(request).strip.should == "It's FIRST POST!"
    request = request('/with_no_behavior/5')
    app.call(request).strip.should == "record 5"
  end

  it "raises an error if no route matches" do
    request = request('/resource_that_doesnt_exist/5')
    expect do
      app.call(request)
    end.to raise_error(Raptor::NoRouteMatches)
  end
end

