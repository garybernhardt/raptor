require "raptor/shorty"

module Injectables
  def self.post_params(params)
    params.fetch(:post)
  end
end

module Interactors
  class CreatePost
    class PostSaved < Struct.new(:current_user, :post); end
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

