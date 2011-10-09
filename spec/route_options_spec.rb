require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/router"
require_relative "../lib/raptor/responders"

describe Raptor::RouteOptions do
  include Raptor

  let(:resource) { stub("resource") }

  it "knows actions for exceptions" do
    options = RouteOptions.new(resource,
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
      action = :show
      ActionTemplateResponder.stub(:new).
        with(resource, :one, action).
        and_return(responder)
      options = RouteOptions.new(resource, {:present => :one})
      options.responder_for(:show).should == responder
    end

    it "renders the action's template by default" do
      template_responder = stub
      ActionTemplateResponder.stub(:new).with(resource, :one, :show).
        and_return(template_responder)
      options = RouteOptions.new(resource, :present => :one)
      options.responder_for(:show).should == template_responder
    end

    it "uses the explicit template if one is given" do
      template_responder = stub
      TemplateResponder.stub(:new).with(resource, :one, "show").
        and_return(template_responder)
      options = RouteOptions.new(resource, :present => :one, :render => "show")
      options.responder_for(:show).should == template_responder
    end
  end

  it "delegates to nothing when there's no :to" do
    options = RouteOptions.new(resource, {})
    options.delegate_name.should == "Raptor::NullDelegate.do_nothing"
  end
end

