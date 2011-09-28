require './spec/spec_helper'

describe Raptor::App do
  def app
    Raptor::App.new([FakeResources::Post, FakeResources::WithNoBehavior])
  end

  it "routes to multiple resources" do
    env = env('GET', '/post/5')
    app.call(env).body.join('').strip.should == "It's FIRST POST!"
    env = env('GET', '/with_no_behavior/5')
    app.call(env).body.join('').strip.should == "record 5"
  end

  it "raises an error if no route matches" do
    env = env('GET', '/resource_that_doesnt_exist/5')
    expect do
      app.call(env)
    end.to raise_error(Raptor::NoRouteMatches)
  end
end

