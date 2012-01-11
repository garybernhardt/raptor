module Models
  class User
    extend Raptor::Model
    delegate [:email, :posts] => :@record

    def anonymous?; false; end
  end

  class AnonymousUser
    def anonymous?; true; end
  end

  class Post
    extend Raptor::Model
    delegate [:title, :body] => :@record

    def publish
      @record.update_attributes(:published => true)
      @record.save!
    end

    def save_as_draft
      @record.update_attributes(:published => false)
      @record.save!
    end
  end
end

