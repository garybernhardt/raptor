module FakeResources; end
module FakeResources::Post
  # A resource with:
  #   - One record, ID 5, whose title is "first post"
  #   - A presenter that upcases records' titles
  #   - A template that says "It's #{post.title}!"
  #   - A route that redirects to a domain object

  def self.routes
    Raptor.routes(self) do
      new :to => 'FakeResources::Post::Record.new'
      show :to => 'FakeResources::Post::Record.find_by_id'
      update :to => 'FakeResources::Post::UpdatesPosts.update!'
    end
  end

  class PresentsOne
    def initialize(record)
      @record = record
    end

    def title
      @record.title.upcase
    end
  end

  class PresentsMany
  end

  class LoggedInRequirement
  end

  class NotSupportedError < Exception
  end

  class UpdatesPosts
    def self.update!
      raise NotSupportedError
    end
  end

  class Record
    def title
      "first post"
    end

    def self.find_by_id(id)
      records = {5 => Record.new()}
      records.fetch(id)
    end
  end
end

module FakeResources::WithNoBehavior
  def self.routes
    Raptor.routes(self) do
      edit
      update
      new
      show
      index
      create
      destroy
    end
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

  class Record < Struct.new(:id, :name)
    def self.all
      [Record.new(1, "alice"), Record.new(2, "bob")]
    end

    def self.find_by_id(id)
      Record.new(id)
    end
  end
end

module FakeResources::WithUndefinedMethodCallInIndex
  def self.routes
    Raptor.routes(self) do
      index
    end
  end
end

