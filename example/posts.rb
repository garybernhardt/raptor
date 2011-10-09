require_relative 'fake_record'

module Posts
  Routes = Raptor.routes(self) do
    root :render => "root", :present => :many
    index
    new
    show
    create
    edit
    update
    destroy
  end

  class PresentsOne
    takes :record
    let(:id) { @record.id }
    let(:title) { @record.title }
  end

  class PresentsMany
    let(:all) { Record.all }
  end

  class Record < FakeRecord.new(:title)
  end
end

