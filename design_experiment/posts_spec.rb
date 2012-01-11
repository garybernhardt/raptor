require_relative "posts"

module Models; class Post; end; end

describe Interactors::CreatePost do
  Post = Models::Post
  CreatePost = Interactors::CreatePost
  PostSaved = Interactors::CreatePost::PostSaved
  ValidationFailure = Interactors::CreatePost::ValidationFailure

  let(:post_params) { stub(:post_params) }

  context "when the post is valid" do
    let(:post) { stub(:post, :valid? => true) }
    before { Post.stub(:new).with(post_params) { post } }

    it "publishes the post if the user is an admin" do
      user = stub(:user, :admin? => true)
      post.should_receive(:publish)
      CreatePost.create(user, post_params)
    end

    it "saves the post as a draft if the user isn't an admin" do
      user = stub(:user, :admin? => false)
      post.should_receive(:save_as_draft)
      CreatePost.create(user, post_params)
    end

    it "returns a post saved response" do
      user = stub(:user, :admin? => false)
      post.stub(:save_as_draft)
      response = CreatePost.create(user, post_params)
      response.should be_a PostSaved
    end
  end

  it "raises a validation failure when the post is invalid" do
    user = stub(:user)
    post = stub(:post, :valid? => false)
    Post.stub(:new).with(post_params) { post }
    expect do
      CreatePost.create(user, post_params)
    end.to raise_error(ValidationFailure)
  end
end

