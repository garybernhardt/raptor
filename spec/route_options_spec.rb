require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/router"
require_relative "../lib/raptor/responders"

describe Raptor::RouteOptions do
  let(:app_module) { stub(:app_module) }
  let(:parent_path) { "posts" }

  it "knows actions for exceptions" do
    options = Raptor::RouteOptions.new(app_module,
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
        with(app_module, "post", parent_path, :show).
        and_return(responder)
      options = Raptor::RouteOptions.new(app_module,
                                         parent_path,
                                         {:present => "post"})
      options.responder_for(:show).should == responder
    end

    it "renders the action's template by default" do
      template_responder = stub
      Raptor::ActionTemplateResponder.stub(:new).
        with(app_module, "post", parent_path, :show).
        and_return(template_responder)
      options = Raptor::RouteOptions.new(app_module,
                                         parent_path,
                                         :present => "post")
      options.responder_for(:show).should == template_responder
    end

    it "uses the explicit template if one is given" do
      template_responder = stub
      Raptor::TemplateResponder.stub(:new).
        with(app_module, "post", "show").
        and_return(template_responder)
      options = Raptor::RouteOptions.new(
        app_module, parent_path, :present => "post", :render => "show")
      options.responder_for(:show).should == template_responder
    end
  end

  it "delegates to nothing when there's no :to" do
    options = Raptor::RouteOptions.new(app_module, parent_path, {})
    options.delegate_name.should == "Raptor::NullDelegate.do_nothing"
  end
end

