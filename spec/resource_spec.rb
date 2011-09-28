require './spec/spec_helper'

describe Raptor::Resource do
  def camel_case_resource; Raptor::Resource.new(stub(:name => 'CamelCase')); end
  def resource; Raptor::Resource.new(FakeResources::Post); end

  it "knows resources' names" do
    camel_case_resource.resource_name.should == 'CamelCase'
  end

  it "knows resources' path components" do
    camel_case_resource.path_component.should == 'camel_case'
  end

  it "knows how to get the record class" do
    resource.record_class.should == FakeResources::Post::Record
  end

  it "knows how to get the one presenter" do
    resource.one_presenter.should == FakeResources::Post::PresentsOne
  end

  it "knows how to get the many presenter" do
    resource.many_presenter.should == FakeResources::Post::PresentsMany
  end
end

