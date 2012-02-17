require_relative 'fake_record'

module Blog
  module Presenters
    class Post
      takes :subject
      let(:id) { p @subject; @subject.id }
      let(:title) { @subject.title }
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

