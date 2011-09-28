#!/usr/bin/env ruby

require_relative '../lib/raptor'
require './posts'

App = Raptor::App.new([Posts])

