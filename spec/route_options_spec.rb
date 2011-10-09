require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/router"
require_relative "../lib/raptor/responders"

describe Raptor::RouteOptions do
  include Raptor

  it "knows actions for exceptions" do
    options = RouteOptions.new(stub('resource'),
                               :redirect => :show,
                               IndexError => :index)
    options.exception_actions.should == {IndexError => :index}
  end

  context "responders" do
    it "creates responders for action templates" do
      resource = stub(:path_component => "/posts", :one_presenter => stub)
      responder = stub
      action = :show
      ActionTemplateResponder.stub(:new).
        with(resource, :one, action).
        and_return(responder)
      options = RouteOptions.new(resource, {:present => :one})
      options.responder_for(:show).should == responder
    end
  end
end

