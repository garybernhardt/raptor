#!/usr/bin/env ruby

require_relative '../lib/raptor'
require_relative 'posts'

App = Raptor::App.new([Posts])

