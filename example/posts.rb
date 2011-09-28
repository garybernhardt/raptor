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

  class Record < Struct.new(:id, :title)
    def self.create(params)
      id = all.length + 1
      record = new(id, params.fetch('title'))
      all << record
      record
    end

    def self.find_by_id(id)
      all.find { |post| post.id == id }
    end

    def self.all
      @posts ||= []
    end

    def find_by_id(id)
      @posts.fetch(id)
    end
  end
end

