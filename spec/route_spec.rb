require './spec/spec_helper'

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    request = request('/post/5')
    rendered = FakeResources::Post::Routes.call(request)
    rendered.strip.must_equal "It's FIRST POST!"
  end

  it "routes requests to new" do
    request = request('/post/new')
    rendered = FakeResources::Post::Routes.call(request)
    rendered.strip.must_equal "<form>\n</form>"
  end

  describe "when a route isn't defined" do
    it "raises an error" do
      request = request('/doesnt_exist')
      Proc.new do
        FakeResources::Post::Routes.call(request)
      end.must_raise(Raptor::NoRouteMatches)
    end
  end

  it "has an index" do
    request = request('/with_no_behavior/index')
    FakeResources::WithNoBehavior::Routes.call(request).strip.must_equal "The index!"
  end

  it "raises an error when templates access undefined methods" do
    request = request('/with_undefined_method_call_in_index/index')
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

