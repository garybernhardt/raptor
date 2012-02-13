require "rack"
require "spec_helper"
require "raptor"

describe Raptor::Router do
  describe "when a route isn't defined" do
    it "raises an error" do
      env = env('GET', '/doesnt_exist')
      router = Raptor::Router.new(stub(:app_module), [])
      response = router.call(env)
      response.status.should == 404
    end
  end
end

