require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/responders"
require_relative "../lib/raptor/inference"

describe Raptor::RedirectResponder do
  before { Raptor.stub(:log) }

  let(:resource) do
    # XXX: #loldemeter
    routes = stub
    routes.stub(:route_named).with(:show).
      and_return(stub(:path => "/my_resource/:id"))
    routes.stub(:route_named).with(:index) { stub(:path => "/my_resource") }
    stub(:name => "my_resource", :routes => routes)
  end

  it "fills route variables with record methods" do
    response = redirect_to_action(:show, stub('record', :id => 1))
    response.status.should == 302
    response['Location'].should == "/my_resource/1"
  end

  it "redirects to routes without variables in them" do
    response = redirect_to_action(:index, stub('record'))
    response.status.should == 302
    response['Location'].should == "/my_resource"
  end

  def redirect_to_action(action, record)
    responder = Raptor::RedirectResponder.new(resource, action)
    inference_sources = {}
    response = responder.respond(record, inference_sources)
  end
end

describe Raptor::ActionTemplateResponder do
  include Raptor

  it "renders templates" do
    resource = stub(:path_component => "posts",
                    :one_presenter => APresenter)
    responder = ActionTemplateResponder.new(resource, :one, "show")
    record = stub
    inference = Inference.new({})
    Template.stub(:render).with(APresenter.new, "posts/show.html.erb").
      and_return("it worked")
    response = responder.respond(record, inference)
    response.body.join.strip.should == "it worked"
  end
end

class APresenter
  @@instance = new

  def self.new
    @@instance
  end
end

