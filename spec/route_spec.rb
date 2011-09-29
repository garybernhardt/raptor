require './spec/spec_helper'

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    request = request('GET', '/post/5')
    rendered = FakeResources::Post::Routes.call(request)
    rendered.body.join('').strip.should == "It's FIRST POST!"
  end

  it "knows routes' paths" do
    resource = stub
    router = Raptor::Router.new(resource) do
      route(:my_action, "GET", "/things/:id", "Object.new")
    end
    router.route_named(:my_action).path.should == "/things/:id"
  end

  describe "when a route isn't defined" do
    it "raises an error" do
      request = request('GET', '/doesnt_exist')
      expect do
        FakeResources::Post::Routes.call(request)
      end.to raise_error(Raptor::NoRouteMatches)
    end
  end

  describe "default routes" do
    include FakeResources::WithNoBehavior

    context "index" do
      it "finds all records" do
        request = request('GET', '/with_no_behavior')
        Routes.call(request).body.join('').strip.should match /record 1\s+record 2/
      end
    end

    context "show" do
      it "retrieves a single record" do
        request = request('GET', '/with_no_behavior/2')
        Routes.call(request).body.join('').strip.should == "record 2"
      end
    end

    context "new" do
      it "renders a template" do
        request = request('GET', '/with_no_behavior/new')
        Routes.call(request).body.join('').strip.should == "<form></form>"
      end
    end

    context "create" do
      let(:bob) { stub(:name => "joe", :id => 7) }
      let(:req) do
        request('POST', '/with_no_behavior', StringIO.new('name=joe'))
      end

      before do
        Record.stub(:create) { bob }
      end

      it "creates records" do
        Record.should_receive(:create)
        Routes.call(req)
      end

      it "redirects to show" do
        response = Routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior/7"
      end

      it "re-renders new on errors" do
        Record.stub(:create).and_raise(Raptor::ValidationError)
        Raptor::Template.stub(:new).with(anything, anything, :new).
          and_return(stub(:render => "<form>New</form>"))
        response = Routes.call(req)
        response.body.join('').strip.should == "<form>New</form>"
      end

      it "ignores exceptions that aren't handled"
    end

    context "edit" do
      it "renders a template" do
        request = request('GET', '/with_no_behavior/7/edit')
        Routes.call(request).body.join('').strip.should == "<form>Edit</form>"
      end
    end

    context "update" do
      let(:bob) { stub(:name => "joe", :id => 7) }

      let(:req) do
        request('PUT', '/with_no_behavior/7', StringIO.new('name=joe'))
      end

      before do
        Record.stub(:find_and_update) { bob }
      end

      it "updates records" do
        Record.should_receive(:find_and_update)
        Routes.call(req)
      end

      it "redirects to show" do
        response = Routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior/7"
      end

      it "re-renders edit on failure" do
        Record.stub(:find_and_update).and_raise(Raptor::ValidationError)
        Raptor::Template.stub(:new).with(anything, anything, :edit).
          and_return(stub(:render => "<form>Edit</form>"))
        response = Routes.call(req)
        response.body.join('').strip.should == "<form>Edit</form>"
      end
    end

    context "destroy" do
      let(:req) { request('DELETE', '/with_no_behavior/7', StringIO.new('')) }

      it "destroys records" do
        Record.should_receive(:destroy)
        Routes.call(req)
      end

      it "redirects to index" do
        Record.stub(:destroy)
        response = Routes.call(req)
        response.status.should == 302
        response['Location'].should == "/with_no_behavior"
      end
    end
  end

  it "rejects route sets with multiple routes for the same verb/path"
  it "sets no-cache by default"
end

