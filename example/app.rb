#!/usr/bin/env ruby

require_relative '../lib/raptor'
require_relative 'posts'

module Blog
  App = Raptor::App.new(self) do
    root :render => "root", :present => :post_list
    path "post" do
      index
      new
      show
      create
      edit
      update
      destroy
    end
  end
end

