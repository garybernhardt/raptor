require_relative 'fake_record'

module Presenters
  class Post
    takes :post
    let(:id) { @post.id }
    let(:title) { @post.title }
  end

  class PostList
    let(:all) { Records::Post.all }
  end
end

module Records
  class Record < FakeRecord.new(:title)
  end
end

