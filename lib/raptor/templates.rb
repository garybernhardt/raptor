require "tilt"

module Raptor
  class FindsLayouts
    LAYOUT_FILENAME = 'layout.html.erb'
    def self.find(path)
      in_same_dir = File.join('views', path, LAYOUT_FILENAME)
      in_root_dir = File.join('views', LAYOUT_FILENAME)
      if File.exist?(in_same_dir)
        Layout.from_path(in_same_dir)
      elsif File.exist?(in_root_dir)
        Layout.from_path(in_root_dir)
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
    attr_reader :tilt
    def initialize(tilt)
      @tilt = tilt
    end

    def self.from_path(path)
      new(Tilt.new(path))
    end

    def ==(other)
      other.is_a?(Layout) &&
        other.tilt == tilt
    end

    def render(inner, presenter)
      @tilt.render { inner.render(presenter) }
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
