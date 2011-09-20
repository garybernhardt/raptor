require 'raptor'

module FakeResources; end
module FakeResources::Post
  # A resource with:
  #   - One record, ID 5, whose title is "first post"
  #   - A presenter that upcases records' titles
  #   - A template that says "It's #{post.title}!"

  Routes = Raptor.routes(self) do
    show 'Posts::Record#find_by_id'
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
    env = {'PATH_INFO' => '5'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.strip.should == "It's FIRST POST!"
  end

  it "knows the name of resources with camel cased names" do
    Raptor::Routes.new(stub(:name => 'CamelCase')).resource_name.should == 'camel_case'
  end

  it "raises an error when templates access undefined variables"
end

