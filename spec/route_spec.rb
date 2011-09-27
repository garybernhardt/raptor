require './spec/spec_helper'

describe Raptor::Router do
  it "routes requests through the record, presenter, and template" do
    request = request('GET', '/post/5')
    rendered = FakeResources::Post::Routes.call(request)
    rendered.strip.should == "It's FIRST POST!"
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
        Routes.call(request).strip.should match /record 1\s+record 2/
      end
    end

    context "show" do
      it "retrieves a single record" do
        request = request('GET', '/with_no_behavior/2')
        Routes.call(request).strip.should == "record 2"
      end
    end

    context "new" do
      it "renders a template" do
        request = request('GET', '/with_no_behavior/new')
        Routes.call(request).strip.should == "<form></form>"
      end
    end

    context "create" do
      it "creates records" do
        bob = stub(:name => "bob", :id => 7)
        request = request('POST', '/with_no_behavior', StringIO.new('name=bob'))
        Record.last.name.should == "bob"
      end

      it "redirects to show"
    end

    context "edit" do
      it "renders a template"
    end

    context "update" do
      it "updates records"
      it "redirects to show"
    end

    context "destroy" do
      it "destroys records"
    end
  end
end

