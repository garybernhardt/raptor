require 'erb'
require 'rack'

require_relative 'raptor/shorty'
require_relative 'raptor/router'
require_relative 'raptor/injector'
require_relative 'raptor/responders'
require_relative 'raptor/delegation'
require_relative 'raptor/validation'

module Raptor
  # XXX: Instead of giving the resource when a route is defined, pass it in
  # when the app calls the route. That simplifies route declaration and will
  # probably simplify the object graph as well.
  def self.routes(app_module, &block)
    Router.build(app_module, &block)
  end

  class App
    def initialize(app_module)
      @app_module = app_module
    end

    def call(env)
      return Rack::MethodOverride.new(@app_module::Routes).call(env)
    end
  end

  class ValidationError < RuntimeError; end

  module Util
    def self.underscore(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end

    def self.camel_case(string)
      string.gsub(/(^|_)(.)/) { $2.upcase } 
    end
  end

  def self.log(text)
    puts "Raptor: #{text}" if ENV['RAPTOR_LOGGING']
  end
end

