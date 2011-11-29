require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"
require_relative "fake_resources"

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    request = request('GET', '/post/5')
    rendered = FakeResources::Post.routes.call(request)
    rendered.body.join('').strip.should == "It's FIRST POST!"
  end

  describe "when a route isn't defined" do
    it "raises an error" do
      request = request('GET', '/doesnt_exist')
      expect do
        FakeResources::Post.routes.call(request)
      end.to raise_error(Raptor::NoRouteMatches)
    end
  end

  it "delegates to the named object, not just Record" do
    request = request('PUT', '/post/5')
    expect do
      FakeResources::Post.routes.call(request)
    end.to raise_error(FakeResources::Post::NotSupportedError)
  end

  it "allows overriding of redirect in standard routes" do
    # XXX: Remove circular reference between resource and route
    resource = stub
    builder = Raptor::BuildsRoutes.new(resource)
    route = builder.route(:index, "GET", "/resource",
                          :to => "Object.new", :redirect => :index)
    resource.stub(:routes) { Raptor::Router.new(resource, [route]) }
    request = request("GET", "/resource")

    response = route.respond_to_request(request)
    response.status.should == 302
    response["Location"].should == "/resource"
  end

  it "can render text" do
    class Resource
      def self.routes
        Raptor.routes(self) do
          index :to => "Object.new", :text => "the text"
        end
      end
    end

    req = request("GET", "/resource")
    Resource.routes.call(req).body.join.strip.should == "the text"
  end

  describe "routes" do
    let(:resource) do
      resource = stub(:resource_name => "Things",
                      :class_named => Object,
                      :one_presenter => Class.new,
                      :path_component => "things")
    end

    let(:router) do
      router = Raptor::Router.build(resource) do
        route(:my_action, "GET", "/things", :to => "Object.delegate",
              :text => "")
      end
    end

    let(:req) { request("GET", "/things") }

    it "propagates exceptions raised in delegates" do
      Object.stub(:delegate).and_raise(RuntimeError)
      expect { router.call(req) }.to raise_error(RuntimeError)
    end

    it "knows routes' paths" do
      router.route_named(:my_action).path.should == "/things"
    end

    describe "requirements" do
      # XXX: Isolate these specs
      it "raises an error if the requirement doesn't match" do
        resource = stub(:requirements => [FailingRequirement])
        router = Raptor::Router.build(resource) do
          route(:my_action, "GET", "/things",
                :to => "Object.new", :require => :failing)
        end
        expect do
          router.call(req)
        end.to raise_error(Raptor::NoRouteMatches)
      end

      it "runs normally if the requirement matches" do
        pending "Why isn't this failing? It references FailingRequirement, not MatchingRequirement"
        resource.stub(:requirements => [FailingRequirement])
        router = Raptor::Router.build(resource) do
          route(:my_action, "GET", "/things",
                :to => "Object.new", :require => :matching,
                :text => "it worked")
        end
        router.call(req).body.join('').strip.should == "it worked"
      end

      it "injects arguments into the requirement" do
        resource.stub(:requirements => [ArgumentRequirement])
        router = Raptor::Router.build(resource) do
          route(:my_action, "GET", "/things",
                :to => "Object.new", :require => :argument,
                :text => "it worked")
        end
        router.call(req).body.join('').strip.should == "it worked"
      end
    end

    describe "root route" do
      it "is a normal route" do
        router = Raptor::Router.build(resource) do
          root :text => "it worked"
        end
        req = request("GET", "/")
        router.call(req).body.join.strip.should == "it worked"
      end
    end
  end

  describe "default routes" do
    include FakeResources::WithNoBehavior
    def routes
      FakeResources::WithNoBehavior.routes
    end

    context "index" do
      it "finds all records" do
        request = request('GET', '/with_no_behavior')
        body = routes.call(request).body.join('').strip
        body.should match /record 1\s+record 2/
      end
    end

    context "show" do
      it "retrieves a single record" do
        request = request('GET', '/with_no_behavior/2')
        routes.call(request).body.join('').strip.should == "record 2"
      end
    end

    context "new" do
      it "renders a template" do
        request = request('GET', '/with_no_behavior/new')
        routes.call(request).body.join('').strip.should == "<form>New</form>"
      end
    end

    context "create" do
      let(:bob) { stub(:name => "bob", :id => 7) }
      let(:req) do
        request('POST', '/with_no_behavior', StringIO.new('name=bob'))
      end

      before do
        Record.stub(:create) { bob }
      end

      it "creates records" do
        Record.should_receive(:create)
        routes.call(req)
      end

      it "redirects to show" do
        response = routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior/7"
      end

      it "re-renders new on errors" do
        Record.stub(:create).and_raise(Raptor::ValidationError)
        response = routes.call(req)
        response.body.join('').strip.should == "<form>New</form>"
      end
    end

    context "edit" do
      it "renders a template" do
        request = request('GET', '/with_no_behavior/7/edit')
        routes.call(request).body.join('').strip.should == "<form>Edit</form>"
      end
    end

    context "update" do
      let(:bob) { stub(:name => "bob", :id => 7) }

      let(:req) do
        request('PUT', '/with_no_behavior/7', StringIO.new('name=bob'))
      end

      before do
        Record.stub(:find_and_update) { bob }
      end

      it "updates records" do
        Record.should_receive(:find_and_update)
        routes.call(req)
      end

      it "redirects to show" do
        response = routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior/7"
      end

      it "re-renders edit on failure" do
        Record.stub(:find_and_update).and_raise(Raptor::ValidationError)
        response = routes.call(req)
        response.body.join('').strip.should == "<form>Edit</form>"
      end
    end

    context "destroy" do
      let(:req) { request('DELETE', '/with_no_behavior/7', StringIO.new('')) }

      it "destroys records" do
        Record.should_receive(:destroy)
        routes.call(req)
      end

      it "redirects to index" do
        Record.stub(:destroy)
        response = routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior"
      end
    end
  end

  it "tunnels PUTs over POSTs"
  it "tunnels DELETEs over POSTs"
  it "stores templates in templates directory, not views"
  it "allows overriding of the presenter class"
  it "uses consistent degelate terminology instead of sometimes calling them records"
  it "doesn't require .html.erb on template names"
end

class FailingRequirement
  def self.match?
    false
  end
end

class MatchingRequirement
  def self.match?
    true
  end
end

class ArgumentRequirement
  def self.match?(path)
    true
  end
end

