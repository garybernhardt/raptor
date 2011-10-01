require 'erb'
require 'rack'

require_relative 'raptor/shorty'
require_relative 'raptor/router'
require_relative 'raptor/inference'
require_relative 'raptor/responders'
require_relative 'raptor/delegation'

module Raptor
  def self.routes(resource, &block)
    resource = Resource.new(resource)
    Router.new(resource, &block)
  end

  class App
    def initialize(resources)
      @resources = resources
    end

    def call(env)
      request = Rack::Request.new(env)
      Raptor.log "App: routing #{request.request_method} #{request.path_info}"
      @resources.each do |resource|
        begin
          return resource::Routes.call(request)
        rescue NoRouteMatches
        end
      end

      raise NoRouteMatches
    end
  end

  class Resource
    def initialize(resource)
      @resource = resource
    end

    def path_component
      Raptor::Util.underscore(resource_name)
    end

    def resource_name
      @resource.name.split('::').last
    end

    def class_named(name)
      @resource.const_get(name)
    end

    def one_presenter
      @resource.const_get(:PresentsOne)
    end

    def many_presenter
      @resource.const_get(:PresentsMany)
    end

    def routes
      @resource::Routes
    end

    def requirements
      class_names = @resource.constants.select { |c| c =~ /Requirement$/ }
      class_names.map { |c| @resource.const_get(c) }
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

