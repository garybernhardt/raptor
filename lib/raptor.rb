module Raptor
  def self.routes(resource)
    Routes.new(resource)
  end

  class Routes
    def initialize(resource)
      @resource = resource
      @resource_name = resource.name.split('::').last
    end

    def call(env)
      id = env['PATH_INFO'].to_i
      record = record_class.find_by_id(id)
      one_presenter.new(record).name
    end

    def record_class
      @resource.const_get(:Record)
    end

    def one_presenter
      @resource.const_get(:PresentsOne)
    end
  end
end

