require "tilt"

module Raptor
  class FindsLayouts
    LAYOUT_FILENAME = 'layout.html.erb'
    def self.find(path)
      in_same_dir = File.join('views', path, LAYOUT_FILENAME)
      in_root_dir = File.join('views', LAYOUT_FILENAME)
      if File.exist?(in_same_dir)
        Layout.new(in_same_dir)
      elsif File.exist?(in_root_dir)
        Layout.new(in_root_dir)
      else
        NullLayout
      end
    end
  end

  class NullLayout
    def self.render(inner, presenter)
      inner.render(presenter)
    end
  end

  class Layout
    attr_reader :path
    def initialize(path)
      @path = path
    end

    def ==(other)
      other.is_a?(Layout) &&
        other.path == path
    end

    def render(inner, presenter)
      context = ViewContext.new(presenter)
      rendered = inner.render(context)
      Tilt.new(@path).render(context) { rendered }
    end
  end

  class ViewContext < BasicObject
    def initialize(presenter)
      @presenter = presenter
      @areas = {}
    end

    def content_for(name, &block)
      if block
        @areas[name] ||= []
        @areas[name] << block.call 
      else
        @areas[name].join
      end
    end

    def method_missing(name, *args, &block)
      @presenter.send(name, *args, &block)
    end
  end

  class Template
    def initialize(tilt)
      @tilt = tilt
    end

    def render(presenter)
      @tilt.render(presenter)
    end

    def self.from_path(template_path)
      path = full_template_path(template_path)
      tilt = Tilt.new(path)
      new(tilt)
    end

    def self.full_template_path(template_path)
      template_path = "/#{template_path}" unless template_path =~ /^\//
      "views#{template_path}"
    end
  end
end
