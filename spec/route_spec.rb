require 'raptor'
require 'fake_resources'

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    env = {'PATH_INFO' => '/posts/5'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.strip.should == "It's FIRST POST!"
  end

  it "routes requests to new" do
    env = {'PATH_INFO' => '/posts/new'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.strip.should == "<form>\n</form>"
  end

  it "raises an error when templates access undefined variables"
end

describe Raptor::RoutePath do
  context "route matching" do
    it "matches if the paths are the same" do
      matches?('/posts/new', '/posts/new').should be_true
    end

    it "does not match when the paths are different" do
      matches?('/posts/new', '/foo/bar').should be_false
    end

    it "matches any component when a path has a param" do
      matches?('/posts/:id', '/posts/5').should be_true
    end

    it "does not a path with params when the path does not match" do
      matches?('/posts/:id', '/users/2').should be_false
    end

    def matches?(route, url)
      Raptor::RoutePath.new(route).matches?(url)
    end
  end

  context "pulling the args out of a route spec and an incoming path" do
    it "pulls out args that match with keywords" do
      Raptor::RoutePath.new('/posts/:id').extract_args('/posts/5').should == [5]
    end
  end

  it "raises an appropriate error when a route isn't defined (currently NoMethodError on nil)"
  it "chooses the correct route even if one with a variable appears before one without"
end

describe Raptor::Resource do
  let(:camel_case_resource) { Raptor::Resource.new(stub(:name => 'CamelCase')) }
  let(:resource) { Raptor::Resource.new(FakeResources::Post) }

  it "knows the name of resources with camel cased names" do
    camel_case_resource.resource_name.should == 'camel_case'
  end

  it "knows how to get the record class" do
    resource.record_class.should == FakeResources::Post::Record
  end

  it "knows how to get the presenter" do
    resource.one_presenter.should == FakeResources::Post::PresentsOne
  end
end

