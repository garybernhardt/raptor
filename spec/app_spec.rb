require './spec/spec_helper'

describe Raptor::App do
  def app
    Raptor::App.new([FakeResources::Post, FakeResources::WithNoBehavior])
  end

  it "routes to multiple resources" do
    request = request('/post/5')
    app.call(request).strip.must_equal "It's FIRST POST!"
    request = request('/with_no_behavior/5')
    app.call(request).strip.must_equal "record 1"
  end

  it "raises an error if no route matches" do
    request = request('/resource_that_doesnt_exist/5')
    Proc.new do
      app.call(request)
    end.must_raise(Raptor::NoRouteMatches)
  end
end

