require "rack"
require_relative "spec_helper"
require "raptor"

describe Raptor::RouteOptions do
  let(:app) { stub(:app) }
  let(:parent_path) { "posts" }

  it "knows actions for exceptions" do
    options = Raptor::RouteOptions.new(app,
                                       "posts",
                                       :redirect => :show,
                                       IndexError => :index)
    options.exception_actions.should == {IndexError => :index}
  end

  context "responders" do
    let(:resource) do
      resource = stub(:path_component => "/posts", :one_presenter => stub)
    end

    it "creates responders for action templates" do
      responder = stub
      Raptor::ActionTemplateResponder.stub(:new).
        with(app, "post", parent_path, :show).
        and_return(responder)
      options = Raptor::RouteOptions.new(app,
                                         parent_path,
                                         :action => :show, :present => "post")
      options.responder.should == responder
    end

    it "renders the action's template by default" do
      template_responder = stub
      Raptor::ActionTemplateResponder.stub(:new).
        with(app, "post", parent_path, :show).
        and_return(template_responder)
      options = Raptor::RouteOptions.new(app,
                                         parent_path,
                                         :action => :show, :present => "post")
      options.responder.should == template_responder
    end

    it "uses the explicit template if one is given" do
      template_responder = stub
      Raptor::TemplateResponder.stub(:new).
        with(app, "post", "show", "/show").
        and_return(template_responder)
      options = Raptor::RouteOptions.new(
        app, parent_path,
        :present => "post", :render => "show", :path => "/show")
      options.responder.should == template_responder
    end

    it "delegates to an action if :redirect is a symbol" do
      action_redirecter = stub
      Raptor::ActionRedirectResponder.stub(:new).
        with(app, :index) { action_redirecter }
      options = Raptor::RouteOptions.new(
        app, parent_path, :redirect => :index)
      options.responder.should == action_redirecter
    end

    it "delegates to a url directly is :redirect is a string" do
      redirecter = stub
      Raptor::RedirectResponder.stub(:new).with('http://google.com') { redirecter }
      options = Raptor::RouteOptions.new(
        app, parent_path, :redirect => 'http://google.com')
      options.responder.should == redirecter
    end

  end

  it "delegates to nothing when there's no :to" do
    app = Raptor::App.new(Object) {}
    options = Raptor::RouteOptions.new(app, parent_path, {})
    injector = Raptor::Injector.new([])
    options.delegator.delegate(injector).should == nil
  end
end

