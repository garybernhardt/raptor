require 'raptor'
require 'fake_resources'

describe Raptor::App do
  it "routes to multiple resources" do
    app = Raptor::App.new([FakeResources::Post, FakeResources::WithNoBehavior])
    env = {'PATH_INFO' => '/post/5'}
    app.call(env).strip.should == "It's FIRST POST!"
    env = {'PATH_INFO' => '/with_no_behavior/5'}
    app.call(env).strip.should == "The index!"
  end

  it "raises an error if no route matches"
end

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    env = {'PATH_INFO' => '/post/5'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.strip.should == "It's FIRST POST!"
  end

  it "routes requests to new" do
    env = {'PATH_INFO' => '/post/new'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.strip.should == "<form>\n</form>"
  end

  context "when a route isn't defined" do
    it "raises an error" do
      env = {'PATH_INFO' => '/doesnt_exist'}
      expect do
        FakeResources::Post::Routes.call(env)
      end.to raise_error(Raptor::NoRouteMatches)
    end
  end

  it "has an index" do
    env = {'PATH_INFO' => '/with_no_behavior/index'}
    FakeResources::WithNoBehavior::Routes.call(env).strip.should == "The index!"
  end

  it "raises an error when templates access undefined methods" do
    env = {'PATH_INFO' => '/with_undefined_method_call_in_index/index'}
    expect do
      FakeResources::WithUndefinedMethodCallInIndex::Routes.call(env)
    end.to raise_error(NameError,
                       /undefined local variable or method `undefined_method'/)
  end
end

describe Raptor::RoutePath do
  context "route matching" do
    it "matches if the paths are the same" do
      matches?('/post/new', '/post/new').should be_true
    end

    it "does not match when the paths are different" do
      matches?('/post/new', '/foo/bar').should be_false
    end

    it "matches any component when a path has a param" do
      matches?('/post/:id', '/post/5').should be_true
    end

    it "does not a path with params when the path does not match" do
      matches?('/post/:id', '/users/2').should be_false
    end

    def matches?(route, url)
      Raptor::RoutePath.new(route).matches?(url)
    end
  end

  context "pulling the args out of a route spec and an incoming path" do
    it "pulls out args that match with keywords" do
      Raptor::RoutePath.new('/post/:id').extract_args('/post/5').should == [5]
    end
  end
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

