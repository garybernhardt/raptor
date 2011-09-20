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

  it "knows the name of resources with camel cased names" do
    Raptor::Route.new(stub, stub, stub, stub(:name => 'CamelCase')).resource_name.should == 'camel_case'
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
    Raptor::Route.new('/posts/new', stub, stub, stub).matches?('/posts/new').should be_true
  end

  it "does not match when the paths are different" do
    Raptor::Route.new('/posts/new', stub, stub, stub).matches?('/foo/bar').should be_false
  end

  it "matches any component when a path has a param" do
    Raptor::Route.new('/posts/:id', stub, stub, stub).matches?('/posts/5').should be_true
  end

  it "does not a path with params when the path does not match" do
    Raptor::Route.new('/posts/:id', stub, stub, stub).matches?('/users/2').should be_false
  end
end

describe "pulling the args out of a route spec and an incoming path" do
  it "pulls out args that match with keywords" do
    Raptor::Route.new('/posts/:id', stub, stub, stub).args_from_incoming_path('/posts/5').should == [5]
  end
end

