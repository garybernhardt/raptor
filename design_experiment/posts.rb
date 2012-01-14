require_relative "fake_raptor"

module Interactors
  class CreatePost
    PostSaved = Struct.new(:current_user, :post)
    class ValidationFailure < RuntimeError
      takes :current_user, :post
    end

    def self.create(current_user, post_params)
      post = Models::Post.new(post_params)
      raise ValidationFailure.new(current_user, post) unless post.valid?

      if current_user.admin?
        post.publish
      else
        post.save_as_draft
      end

      PostSaved.new(current_user, post)
    end
  end
end

module Injectables
  def self.post_params(params)
    params.fetch(:post)
  end
end

module Models
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

