#!/usr/bin/env ruby

require_relative '../lib/raptor'
require_relative 'posts'

module Blog
  Routes = Raptor.routes(self) do
    path "posts" do
      root :render => "root", :present => :many
      index
      new
      show
      create
      edit
      update
      destroy
    end
  end

  App = Raptor::App.new(self)
end

