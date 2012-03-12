require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::App, "integrated" do
  before do
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
  end

  after { Object.send(:remove_const, :App) }

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
    Tilt.stub(:new).with("views/post/index.html.erb").
      and_return(stub(:render => "Template content"))
    env = env('GET', '/post')
    app.call(env).body.join('').strip.should == "Template content"
  end
end

describe Raptor::App, "app wrapping" do
  before do
    module App
      module Presenters
        class Post
        end
      end

      module Injectables
        module Fruit
        end
      end
    end

    module EmptyApp
    end
  end

  after do
    Object.send(:remove_const, :App)
    Object.send(:remove_const, :EmptyApp)
  end

  describe "#presenters" do
    it "lists presenters" do
      app = Raptor::App.new(App)
      app.presenters.should == {:Post => App::Presenters::Post}
    end

    it "lists nothing when the app has no presenter module" do
      app = Raptor::App.new(EmptyApp)
      app.presenters.should == {}
    end
  end

  describe "#injectables" do
    it "lists injectables" do
      app = Raptor::App.new(App)
      app.injectables.should == [App::Injectables::Fruit]
    end

    it "lists nothing when the app has no injectables module" do
      app = Raptor::App.new(EmptyApp)
      app.injectables.should == []
    end
  end
end

