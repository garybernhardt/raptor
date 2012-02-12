class FakeRecord
  def self.new(*attributes)
    record_class = Struct.new(*([:id] + attributes))
    record_class.class_eval do
      def self.create(params)
        title = params.fetch("title")
        raise Raptor::ValidationError unless title.length > 0
        id = all.length + 1
        record = new(id, title)
        all << record
        record
      end

      def self.find_by_id(id)
        all.find { |post| post.id == id.to_i }
      end

      def self.all
        @posts ||= []
      end
    end
    record_class
  end
end

