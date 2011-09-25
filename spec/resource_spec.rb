require 'mocha'
require './spec/spec_helper'

describe Raptor::Resource do
  def camel_case_resource; Raptor::Resource.new(stub(:name => 'CamelCase')); end
  def resource; Raptor::Resource.new(FakeResources::Post); end

  it "knows the name of resources with camel cased names" do
    camel_case_resource.resource_name.must_equal 'camel_case'
  end

  it "knows how to get the record class" do
    resource.record_class.must_equal FakeResources::Post::Record
  end

  it "knows how to get the one presenter" do
    resource.one_presenter.must_equal FakeResources::Post::PresentsOne
  end

  it "knows how to get the many presenter" do
    resource.many_presenter.must_equal FakeResources::Post::PresentsMany
  end
end

