require 'erb'

module Raptor
  def self.routes(resource)
    Router.new(resource)
  end

  class Router
    def initialize(resource)
      @resource = resource
    end

    def resource_name
      underscore(@resource.name.split('::').last)
    end

    def underscore(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end

    def call(env)
      id = env['PATH_INFO'].to_i
      record = record_class.find_by_id(id)
      template = ERB.new(File.new("views/#{resource_name}/show.html.erb").read)
      presenter = one_presenter.new(record)
      template_binder = TemplateBinder.new(resource_name.to_sym => presenter)
      template.result(template_binder.get_binding)
    end

    def record_class
      @resource.const_get(:Record)
    end

    def one_presenter
      @resource.const_get(:PresentsOne)
    end
  end

  class TemplateBinder
    def initialize(params)
      @params = params
    end

    def method_missing(name)
      @params[name] or super
    end

    def get_binding
      binding
    end
  end
end

