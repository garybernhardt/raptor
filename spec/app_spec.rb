require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::App do
  module App
    Routes = Raptor.routes(self) do
      path 'post' do
        index :to => "Object.new"
      end
    end

    module Presenters
      class PostList
      end
    end
  end

  let(:app) { Raptor::App.new(App) }

  describe 'method override' do
    def request_method(method)
      hash_including('REQUEST_METHOD' => method)
    end

    it "tunnels PUT over POST" do
      App::Routes.should_receive(:call).with(request_method('PUT'))
      Raptor::App.new(App).call(env('POST', '/irrelevant',
                                            StringIO.new('_method=PUT')))
    end

    it "tunnels DELETE over POST" do
      App::Routes.should_receive(:call).with(request_method('DELETE'))
      Raptor::App.new(App).call(env('POST', '/irrelevant',
                                               StringIO.new('_method=DELETE')))
    end
  end

  it "routes to resources" do
    File.stub(:new).with("views/post/index.html.erb").
      and_return(stub(:read => "Template content"))
    env = env('GET', '/post')
    app.call(env).body.join('').strip.should == "Template content"
  end
end

