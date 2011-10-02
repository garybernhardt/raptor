require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::App do
  module Resource1
    Routes = Raptor.routes(self) { index :to => "Object.new" }
    class PresentsMany; end
  end

  module Resource2
    Routes = Raptor.routes(self) { index :to => "Object.new" }
    class PresentsMany; end
  end

  let(:app) { Raptor::App.new([Resource1, Resource2]) }

  it "routes to multiple resources" do
    File.stub(:new).with("views/resource1/index.html.erb").
      and_return(stub(:read => "Resource 1 response"))
    File.stub(:new).with("views/resource2/index.html.erb").
      and_return(stub(:read => "Resource 2 response"))
    env = env('GET', '/resource1')
    app.call(env).body.join('').strip.should == "Resource 1 response"
    env = env('GET', '/resource2')
    app.call(env).body.join('').strip.should == "Resource 2 response"
  end

  it "raises an error if no route matches" do
    env = env('GET', '/resource_that_doesnt_exist/5')
    expect do
      app.call(env)
    end.to raise_error(Raptor::NoRouteMatches)
  end
end

