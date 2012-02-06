require_relative 'fake_record'

module Blog
  module Presenters
    class Post
      takes :record
      let(:id) { @record.id }
      let(:title) { @record.title }
    end

    class PostList
      let(:all) { Records::Post.all }
    end
  end

  module Records
    class Post < FakeRecord.new(:title)
    end
  end
end

