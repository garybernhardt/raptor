require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::Router do
  module RouterTestApp
    module Presenters
      class Post
        def initialize(record)
          @record = record
        end

        def title
          @record.title.upcase
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

  it "can render text" do
    routes = Raptor.routes(RouterTestApp) do
      path "posts" do
        index :to => "Object.new", :text => "the text"
      end
    end

    req = request("GET", "/posts")
    routes.call(req).body.join.strip.should == "the text"
  end

  describe "router" do
    it "errors if route_named is asked for a route that doesn't exist"

    describe "root route" do
      it "is a normal route" do
        router = Raptor::Router.build(RouterTestApp) do
          root :text => "it worked"
        end
        req = request("GET", "/")
        router.call(req).body.join.strip.should == "it worked"
      end
    end
  end

  describe "default routes" do
    it "allows overriding of redirect in default routes" do
      request = request("GET", "/post_with_redirect/new")
      response = RouterTestApp::Routes.call(request)
      response.status.should == 302
      # XXX: Why is there a trailing slash on this URL?
      response["Location"].should == "/post_with_redirect/"
    end

    context "index" do
      it "finds all records" do
        request = request('GET', '/post')
        body = RouterTestApp::Routes.call(request).body.join('').strip
        body.should match /record 1\s+record 2/
      end
    end

    context "show" do
      it "retrieves a single record" do
        request = request('GET', '/post/2')
        response = RouterTestApp::Routes.call(request)
        response.body.join('').strip.should == "It's RECORD 2!"
      end
    end

    context "new" do
      it "renders a template" do
        request = request('GET', '/post/new')
        response = RouterTestApp::Routes.call(request)
        response.body.join('').strip.should == "<form>New</form>"
      end
    end

    context "create" do
      let(:req) { request('POST', '/post', StringIO.new("")) }

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
        request = request('GET', '/post/1/edit')
        response = RouterTestApp::Routes.call(request)
        response.body.join('').strip.should == "<form>Edit</form>"
      end
    end

    context "update" do
      let(:req) do
        request('PUT', '/post/7', StringIO.new(''))
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
      let(:req) { request('DELETE', '/post/7', StringIO.new('')) }

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

  it "errors when asked to create guess a presenter for a root URL like GET /" do
    app_module = Module.new
    expect do
      Raptor::BuildsRoutes.new(app_module).index
    end.to raise_error(Raptor::CantInferModulePathsForRootRoutes)
  end

  it "routes to nested routes"
  it "tunnels PUTs over POSTs"
  it "tunnels DELETEs over POSTs"
  it "stores templates in templates directory, not views"
  it "allows overriding of the presenter class"
  it "uses consistent degelate terminology instead of sometimes calling them records"
  it "doesn't require .html.erb on template names"
  it "includes type definitions in routes so they can be casted before injection"
end

class MatchingRequirement
  def self.match?
    true
  end
end

