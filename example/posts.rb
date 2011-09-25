module Posts
  Routes = Raptor.routes(self) do
    index
    show
    new
    create
    edit
    update
    destroy
  end

  class PresentsOne
    def initialize(post)
    end

    def date
      post.date.as_delta
    end

    def highlighted
      post.user.is_admin?
    end

    def mine
      post.user == current_user
    end
  end

  class PresentsMany
  end

  class Record
    def self.posts
      @posts ||= {}
    end

    def find_by_id(id)
      @posts.fetch(id)
    end
  end
end

