require "rack"
require "spec_helper"
require "raptor/router"

describe Raptor::Router do
  describe "when a route isn't defined" do
    it "raises an error" do
      request = request('GET', '/doesnt_exist')
      router = Raptor::Router.new(stub(:app_module), [])
      expect do
        router.call(request)
      end.to raise_error(Raptor::NoRouteMatches)
    end
  end
end

