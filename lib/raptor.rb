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
  def self.routes(resource, &block)
    resource = Resource.new(resource)
    Router.build(resource, &block)
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
          return resource.routes.call(request)
        rescue NoRouteMatches
        end
      end

      raise NoRouteMatches
    end
  end

  class Resource
    def initialize(resource_module)
      @resource_module = resource_module
    end

    def path_component
      Raptor::Util.underscore(resource_name)
    end

    def resource_name
      @resource_module.name.split('::').last
    end

    def class_named(name)
      @resource_module.const_get(name)
    end

    def module_path
      @resource_module.name
    end

    def one_presenter
      @resource_module.const_get(:PresentsOne)
    end

    def many_presenter
      @resource_module.const_get(:PresentsMany)
    end

    def routes
      @resource_module.routes
    end

    def requirements
      class_names = @resource_module.constants.select do
        |c| c =~ /Requirement$/
      end
      class_names.map { |c| @resource_module.const_get(c) }
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

