require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/validation"

describe "route validation" do
  context "the full route" do
    it "rejects routes with exactly the same path and redirects" do
      route = stub(:name => :index, :redirects => {})
      conflicting = stub(:name => :index, :redirects => {})
      routes = [route, conflicting]
      expect do
        Raptor::ValidatesRoutes.validate!(routes)
      end.to raise_error(Raptor::ConflictingRoutes)
    end

    it "doesn't reject routes that have different redirects" do
      with_redirects = stub(:name => :update,
                            :redirects => {:ValidationError => :edit})
      without_redirects =  stub(:name => :update, :redirects => {})
      routes = [with_redirects, without_redirects]
      Raptor::ValidatesRoutes.validate!(routes)
    end
  end

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
