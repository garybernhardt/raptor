module FakeResources; end
module FakeResources::Post
  # A resource with:
  #   - One record, ID 5, whose title is "first post"
  #   - A presenter that upcases records' titles
  #   - A template that says "It's #{post.title}!"

  Routes = Raptor.routes(self) do
    new 'Posts::Record#new'
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

  class PresentsMany
  end

  class Record
    def initialize(params)
    end

    def title
      "first post"
    end

    def self.find_by_id(id)
      records = {5 => Record.new({})}
      records.fetch(id)
    end
  end
end

module FakeResources::WithNoBehavior
  Routes = Raptor.routes(self) do
    show "WithNoBehavior::Record#find_by_id"
    index
    new
  end

  class PresentsOne
    def initialize(record)
      @record = record
    end

    def name
      "record #{@record.id}"
    end
  end

  class PresentsMany
    def all
      FakeResources::WithNoBehavior::Record.all
    end
  end

  class Record < Struct.new(:id)
    def self.all
      [Record.new(1), Record.new(2)]
    end

    def self.find_by_id(id)
      Record.new(id)
    end
  end
end

module FakeResources::WithUndefinedMethodCallInIndex
  Routes = Raptor.routes(self) do
    index
  end
end

