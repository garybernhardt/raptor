require 'minitest/autorun'
require 'mocha'

$LOAD_PATH << "lib" << "spec"
require 'raptor'
require 'fake_resources'

describe Raptor::App do
  def app
    Raptor::App.new([FakeResources::Post, FakeResources::WithNoBehavior])
  end

  it "routes to multiple resources" do
    request = Rack::Request.new({'PATH_INFO' => '/post/5'})
    app.call(request).strip.must_equal "It's FIRST POST!"
    request = Rack::Request.new({'PATH_INFO' => '/with_no_behavior/5'})
    app.call(request).strip.must_equal "The index!"
  end

  it "raises an error if no route matches" do
    request = Rack::Request.new({'PATH_INFO' => '/resource_that_doesnt_exist/5'})
    Proc.new do
      app.call(request)
    end.must_raise(Raptor::NoRouteMatches)
  end
end

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    request = Rack::Request.new({'PATH_INFO' => '/post/5'})
    rendered = FakeResources::Post::Routes.call(request)
    rendered.strip.must_equal "It's FIRST POST!"
  end

  it "routes requests to new" do
    request = Rack::Request.new({'PATH_INFO' => '/post/new'})
    rendered = FakeResources::Post::Routes.call(request)
    rendered.strip.must_equal "<form>\n</form>"
  end

  describe "when a route isn't defined" do
    it "raises an error" do
      request = Rack::Request.new({'PATH_INFO' => '/doesnt_exist'})
      Proc.new do
        FakeResources::Post::Routes.call(request)
      end.must_raise(Raptor::NoRouteMatches)
    end
  end

  it "has an index" do
    request = Rack::Request.new({'PATH_INFO' => '/with_no_behavior/index'})
    FakeResources::WithNoBehavior::Routes.call(request).strip.must_equal "The index!"
  end

  it "raises an error when templates access undefined methods" do
    request = Rack::Request.new({'PATH_INFO' => '/with_undefined_method_call_in_index/index'})
    Proc.new do
      FakeResources::WithUndefinedMethodCallInIndex::Routes.call(request)
    end.must_raise(NameError,
                   /undefined local variable or method `undefined_method'/)
  end

  it "knows when a route matches" do
    FakeResources::Post::Routes.matches?("/post/new").must_equal true
  end

  it "knows when routes don't match" do
    FakeResources::Post::Routes.matches?("/not_a_post/new").must_equal false
  end
end

describe Raptor::RoutePath do
  describe "route matching" do
    it "matches if the paths are the same" do
      matches?('/post/new', '/post/new').must_equal true
    end

    it "does not match when the paths are different" do
      matches?('/post/new', '/foo/bar').must_equal false
    end

    it "matches any component when a path has a param" do
      matches?('/post/:id', '/post/5').must_equal true
    end

    it "does not a path with params when the path does not match" do
      matches?('/post/:id', '/users/2').must_equal false
    end

    def matches?(route, url)
      Raptor::RoutePath.new(route).matches?(url)
    end
  end

  describe "pulling the args out of a route spec and an incoming path" do
    it "pulls out args that match with keywords" do
      Raptor::RoutePath.new('/post/:id').extract_args('/post/5').must_equal [5]
    end
  end
end

describe Raptor::Resource do
  def camel_case_resource; Raptor::Resource.new(stub(:name => 'CamelCase')); end
  def resource; Raptor::Resource.new(FakeResources::Post); end

  it "knows the name of resources with camel cased names" do
    camel_case_resource.resource_name.must_equal 'camel_case'
  end

  it "knows how to get the record class" do
    resource.record_class.must_equal FakeResources::Post::Record
  end

  it "knows how to get the presenter" do
    resource.one_presenter.must_equal FakeResources::Post::PresentsOne
  end
end

