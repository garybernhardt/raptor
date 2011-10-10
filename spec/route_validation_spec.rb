require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/validation"

describe "route validation" do
  context "the route params" do

  it "rejects routes with both a render and a redirect" do
    redirect_and_render = {:redirect => :index, :render => :show}
    expect do
      Raptor::ValidatesRoutes.validate_route_params!(redirect_and_render)
    end.to raise_error(Raptor::ConflictingRoutes)
  end

  it "does not reject route params with just a redirect" do
    just_redirect = {:redirect => :index}
    Raptor::ValidatesRoutes.validate_route_params!(just_redirect)
  end

  it "does not reject route params with just a render" do
    just_render = {:render => :index}
    Raptor::ValidatesRoutes.validate_route_params!(just_render)
  end

  it "does not reject empty route params" do
    empty_params = {}
    Raptor::ValidatesRoutes.validate_route_params!(empty_params)
  end

  end
end
