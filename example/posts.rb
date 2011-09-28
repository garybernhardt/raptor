require_relative 'fake_record'

module Posts
  Routes = Raptor.routes(self) do
    index
    new
    show
    create
    edit
    update
    destroy
  end

  class PresentsOne
    def initialize(post)
      @post = post
    end

    def id
      @post.id
    end

    def title
      @post.title
    end
  end

  class PresentsMany
    def all
      Record.all
    end
  end

  class Record < FakeRecord.new(:title)
  end
end

