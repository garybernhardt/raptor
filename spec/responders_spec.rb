require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::ActionRedirectResponder do
  before { Raptor.stub(:log) }

  let(:app) { stub(:app) }

  let(:route) do
    route = stub
    route.stub(:neighbor_named).with(:show).
      and_return(stub(:path => "/my_resource/:id"))
    route.stub(:neighbor_named).with(:index).
      and_return(stub(:path => "/my_resource"))
    route
  end

  it "fills route variables with record methods" do
    response = redirect_to_action(:show, stub('record', :id => 1))
    response.should redirect_to('/my_resource/1')
  end

  it "redirects to routes without variables in them" do
    response = redirect_to_action(:index, stub('record'))
    response.should redirect_to('/my_resource')
  end

  def redirect_to_action(action, record)
    responder = Raptor::ActionRedirectResponder.new(app, action)
    response = responder.respond(route, record, Raptor::Injector.new)
  end
end

describe Raptor::ActionTemplateResponder do
  it "renders templates" do
    app = stub(:presenters => {"Post" => PostPresenter})
    responder = Raptor::ActionTemplateResponder.new(app, 'post', 'posts', :show)
    record = stub
    route = stub
    injector = Raptor::Injector.new([])
    Raptor::Template.stub(:from_path).with(PostPresenter.new, "posts/show.html.erb")
    layout = stub(:layout)
    layout.stub(:render) { "it worked" }
    Raptor::FindsLayouts.stub(:find).with('posts') { layout }
    response = responder.respond(route, record, injector)
    response.body.join.strip.should == "it worked"
  end
end

class PostPresenter
  @@instance = new

  def self.new
    @@instance
  end
end

