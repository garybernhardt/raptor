require 'raptor'

module FakeResources; end
module FakeResources::Post
  # A resource with:
  #   - One record, ID 5, whose title is "first post"
  #   - A presenter that upcases records' titles
  #   - A template that says "It's #{post.title}!"

  Routes = Raptor.routes(self) do
    show 'Posts::Record#find_by_id'
    new 'Posts::Record#new'
  end

  class PresentsOne
    def initialize(post)
      @post = post
    end

    def title
      @post.title.upcase
    end
  end

  class Record
    def title
      "first post"
    end

    def self.find_by_id(id)
      records = {5 => Record.new}
      records.fetch(id)
    end
  end
end

describe "Router" do
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

describe "Route matching" do
  it "matches if the paths are the same" do
    Raptor::RoutePath.new('/posts/new').matches?('/posts/new').should be_true
  end

  it "does not match when the paths are different" do
    Raptor::RoutePath.new('/posts/new').matches?('/foo/bar').should be_false
  end

  it "matches any component when a path has a param" do
    Raptor::RoutePath.new('/posts/:id').matches?('/posts/5').should be_true
  end

  it "does not a path with params when the path does not match" do
    Raptor::RoutePath.new('/posts/:id').matches?('/users/2').should be_false
  end
end

describe "pulling the args out of a route spec and an incoming path" do
  it "pulls out args that match with keywords" do
    Raptor::RoutePath.new('/posts/:id').extract_args('/posts/5').should == [5]
  end
end

describe Raptor::Resource do
  it "knows the name of resources with camel cased names" do
    Raptor::Resource.new(stub(:name => 'CamelCase')).resource_name.should == 'camel_case'
  end

  it "knows how to get the record class" do
    Raptor::Resource.new(FakeResources::Post).record_class.should == FakeResources::Post::Record
  end

  it "knows how to get the presenter" do
    Raptor::Resource.new(FakeResources::Post).one_presenter.should == FakeResources::Post::PresentsOne
  end
end
