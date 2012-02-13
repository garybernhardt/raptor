require "rack"
require "spec_helper"
require "raptor"

module RouterTestApp
  module Presenters
    class Post
      def initialize(subject)
        @subject = subject
      end

      def title
        @subject.title.upcase
      end
    end
  end

  module Records
    class Post < Struct.new(:id, :title)
      def self.all
        [new(1, "record 1"), new(2, "record 2")]
      end
      def self.find_by_id(id)
        all.find { |post| post.id == id.to_i }
      end
      def self.raises_key_error
        raise KeyError
      end
      def self.create
      end
    end
  end

  module Presenters
    class PostList
      def all
        RouterTestApp::Records::Post.all
      end
    end
  end

  Routes = Raptor::Router.build(self) do
    path "post" do
      new; show; index; create; edit; update; destroy
    end
    path "post_with_redirect" do
      new :to => "RouterTestApp::Records::Post.new",
        :redirect => :index
      index
    end
  end
end

describe "default routes" do
  it "allows overriding of redirect in default routes" do
    env = env("GET", "/post_with_redirect/new")
    response = RouterTestApp::Routes.call(env)
    response.status.should == 302
    # XXX: Why is there a trailing slash on this URL?
    response["Location"].should == "/post_with_redirect/"
  end

  context "index" do
    it "finds all records" do
      env = env('GET', '/post')
      body = RouterTestApp::Routes.call(env).body.join('').strip
      body.should match /record 1\s+record 2/
    end
  end

  context "show" do
    it "retrieves a single record" do
      env = env('GET', '/post/2')
      response = RouterTestApp::Routes.call(env)
      response.body.join('').strip.should == "It's RECORD 2!"
    end
  end

  context "new" do
    it "renders a template" do
      env = env('GET', '/post/new')
      response = RouterTestApp::Routes.call(env)
      response.body.join('').strip.should == "<form>New</form>"
    end
  end

  context "create" do
    let(:req) { env('POST', '/post', StringIO.new("")) }

    before do
      RouterTestApp::Records::Post.stub(:create) { stub(:id => 1) }
    end

    it "creates records" do
      RouterTestApp::Records::Post.should_receive(:create)
      RouterTestApp::Routes.call(req)
    end

    it "redirects to show" do
      response = RouterTestApp::Routes.call(req)
      response.status.should == 302
      response['Location'].should == "/post/1"
    end

    it "re-renders new on errors" do
      RouterTestApp::Records::Post.stub(:create).
        and_raise(Raptor::ValidationError)
      response = RouterTestApp::Routes.call(req)
      response.body.join('').strip.should == "<form>New</form>"
    end
  end

  context "edit" do
    it "renders a template" do
      env = env('GET', '/post/1/edit')
      response = RouterTestApp::Routes.call(env)
      response.body.join('').strip.should == "<form>Edit</form>"
    end
  end

  context "update" do
    let(:req) do
      env('PUT', '/post/7', StringIO.new(''))
    end

    before do
      RouterTestApp::Records::Post.stub(:find_and_update) { stub(:id => 1) }
    end

    it "updates records" do
      RouterTestApp::Records::Post.should_receive(:find_and_update)
      RouterTestApp::Routes.call(req)
    end

    it "redirects to show" do
      response = RouterTestApp::Routes.call(req)
      response.status.should == 302
      response['Location'].should == "/post/1"
    end

    it "re-renders edit on failure" do
      RouterTestApp::Records::Post.stub(:find_and_update).
        and_raise(Raptor::ValidationError)
      response = RouterTestApp::Routes.call(req)
      response.body.join('').strip.should == "<form>Edit</form>"
    end
  end

  context "destroy" do
    let(:req) { env('DELETE', '/post/7', StringIO.new('')) }

    it "destroys records" do
      RouterTestApp::Records::Post.should_receive(:destroy)
      RouterTestApp::Routes.call(req)
    end

    it "redirects to index" do
      RouterTestApp::Records::Post.stub(:destroy)
      response = RouterTestApp::Routes.call(req)
      response.status.should == 302
      # XXX: Why is there a trailing slash on this URL?
      response['Location'].should == "/post/"
    end
  end
end

