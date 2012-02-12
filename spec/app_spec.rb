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

  it "routes to resources" do
    File.stub(:new).with("views/post/index.html.erb").
      and_return(stub(:read => "Template content"))
    env = env('GET', '/post')
    app.call(env).body.join('').strip.should == "Template content"
  end
end

