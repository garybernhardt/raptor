require './spec/spec_helper'
require 'mocha'

describe Raptor::Template do
  it "raises an error when templates access undefined methods" do
    presenter = stub
    resource_name = "posts"
    template_name = "show"
    File.stubs(:new => StringIO.new("<% undefined_method %>"))

    Proc.new do
      Template.new(presenter, resource_name, template_name)
    end.must_raise(NameError,
                   /undefined local variable or method `undefined_method'/)
  end
end

