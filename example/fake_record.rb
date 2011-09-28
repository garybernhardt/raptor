class FakeRecord
  def self.new(*attributes)
    record_class = Struct.new(*([:id] + attributes))
    record_class.class_eval do
      def self.create(params)
        id = all.length + 1
        record = new(id, params.fetch('title'))
        all << record
        record
      end

      def self.find_by_id(id)
        all.find { |post| post.id == id }
      end

      def self.all
        @posts ||= []
      end

      def find_by_id(id)
        @posts.fetch(id)
      end
    end
    record_class
  end
end

