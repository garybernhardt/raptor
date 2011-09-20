require 'raptor'

module FakeResources; end
module FakeResources::Post
  Routes = Raptor.routes(self) do
    show 'Posts::Record#find_by_id'
  end

  class PresentsOne
    def initialize(post)
      @post = post
    end

    def name
      @post.name.upcase
    end
  end

  class Record
    def name
      "bob"
    end

    def self.find_by_id(id)
      records = {5 => Record.new}
      records.fetch(id)
    end
  end
end

describe "Router" do
  it "routes requests through the model and back" do
    env = {'PATH_INFO' => '5'}
    rendered = FakeResources::Post::Routes.call(env)
    rendered.should == "BOB"
  end

  it "knows the name of resources with camel cased names"
end

