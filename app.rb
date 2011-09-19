#!/usr/bin/env ruby

require 'resources/posts'
require 'resources/users'

Raptor.new([Posts, Users]).attack!

