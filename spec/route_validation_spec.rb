require './lib/raptor/validation'

describe "route validation" do
  it "rejects routes with exactly the same path and redirects" do
    route = stub(:name => :index, :redirects => {})
    conflicting = stub(:name => :index, :redirects => {})
    routes = [route, conflicting]
    expect do
      Raptor::ValidatesRoutes.validate!(routes)
    end.to raise_error(Raptor::ConflictingRoutes)
  end

  it "doesn't reject routes that have different redirects" do
    with_redirects = stub(:name => :update, :redirects => {:ValidationError => :edit})
    without_redirects =  stub(:name => :update, :redirects => {})
    routes = [with_redirects, without_redirects]
    Raptor::ValidatesRoutes.validate!(routes)
  end
end
