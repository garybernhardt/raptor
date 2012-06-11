require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::App, "integrated" do
  before do
    module AwesomeSite
      module Presenters
        class PostList
          attr_reader :watermelon

          def initialize(watermelon)
            @watermelon = watermelon
          end
        end
        class Post
        end
      end

      module Constraints
        class OnlyTwos
          def match?(id)
            id == '2'
          end
        end
      end

      module Injectables
        class Fruit
          def sources(injector)
            {:watermelon => lambda { "fruity" } }
          end
        end
      end

      App = Raptor::App.new(self) do
        path 'post' do
          index :to => "Object.new"
          show :to => "Object.new", :if => :only_twos
        end
      end
    end
  end

  after { Object.send(:remove_const, :AwesomeSite) }

  let(:app) { AwesomeSite::App }

  describe 'method override' do
    def request_method(method)
      hash_including('REQUEST_METHOD' => method)
    end

    it "tunnels PUT over POST" do
      AwesomeSite::App.routes.should_receive(:call).
        with(request_method('PUT'))
      app.call(env('POST', '/irrelevant', StringIO.new('_method=PUT')))
    end

    it "tunnels DELETE over POST" do
      AwesomeSite::App.routes.should_receive(:call).
        with(request_method('DELETE'))
      app.call(env('POST', '/irrelevant', StringIO.new('_method=DELETE')))
    end
  end

  it "routes to resources" do
    Tilt.stub(:new).with("views/post/index.html.erb").
      and_return(stub(:render => "Template content"))
    env = env('GET', '/post')
    app.call(env).body.join('').strip.should == "Template content"
  end

  it "matches against custom constraints" do
    Tilt.stub(:new).with("views/post/show.html.erb").
      and_return(stub(:render => "Template content"))
    app.call(env('GET', '/post/1')).status.should == 404
    app.call(env('GET', '/post/2')).status.should_not == 404
    app.call(env('GET', '/post/2')).body.join('').strip.should == "Template content"
  end

  it "injects custom injectables" do
    File.stub(:binread).with("views/post/index.html.erb").
      and_return("<%= watermelon %>")
    app.call(env("GET", "/post")).body.join("").strip.should == "fruity"
  end
end

describe Raptor::App, "app wrapping" do
  before do
    module AwesomeSite
      module Presenters
        class Post
        end
      end

      module Injectables
        module Fruit
        end
      end

      module Constraints
        class Never
        end
      end

      App = Raptor::App.new(self) do
      end
    end

    module EmptySite
      App = Raptor::App.new(self) do
      end
    end
  end

  after do
    Object.send(:remove_const, :AwesomeSite)
    Object.send(:remove_const, :EmptySite)
  end

  describe "#presenters" do
    it "lists presenters" do
      app = AwesomeSite::App
      app.presenters.should == {"Post" => AwesomeSite::Presenters::Post}
    end

    it "lists nothing when the app has no presenter module" do
      app = EmptySite::App
      app.presenters.should == {}
    end
  end

  describe "#injectables" do
    it "lists injectables" do
      app = AwesomeSite::App
      app.injectables.should == [AwesomeSite::Injectables::Fruit]
    end

    it "lists nothing when the app has no injectables module" do
      app = EmptySite::App
      app.injectables.should == []
    end
  end

  describe "#constraint_named" do
    it "has the named constraint" do
      app = AwesomeSite::App
      app.constraint_named(:Never).should == AwesomeSite::Constraints::Never
    end

    it "warns of missing constraints" do
      app = EmptySite::App
      expect do
        app.constraint_named(:DoesNotExist)
      end.to raise_error(Raptor::NoSuchConstraint)
    end
  end
end

