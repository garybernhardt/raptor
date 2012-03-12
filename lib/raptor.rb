require 'erb'
require 'rack'

require_relative 'raptor/shorty'
require_relative 'raptor/router'
require_relative 'raptor/injector'
require_relative 'raptor/templates'
require_relative 'raptor/responders'
require_relative 'raptor/delegation'
require_relative 'raptor/validation'

module Raptor
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

    def presenters
      return {} unless @app_module.const_defined?(:Presenters)
      presenters = @app_module::Presenters
      Hash[
        presenters.constants.map do |const_name|
          [const_name, presenters.const_get(const_name)]
        end
      ]
    end

    def injectables
      return [] unless @app_module.const_defined?(:Injectables)
      presenters = @app_module::Injectables
      presenters.constants.map do |const_name|
        presenters.const_get(const_name)
      end
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

