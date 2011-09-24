#!/usr/bin/env ruby

require 'resources/posts'
require 'resources/users'

Raptor::App.new([Posts, Users]).attack!

