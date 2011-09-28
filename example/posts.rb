require_relative 'fake_record'

module Posts
  Routes = Raptor.routes(self) do
    index
    new
    show
    create
    edit
    update
    destroy
  end

  class PresentsOne
    takes :post
    let(:id) { @post.id }
    let(:title) { @post.title }
  end

  class PresentsMany
    let(:all) { Record.all }
  end

  class Record < FakeRecord.new(:title)
  end
end

