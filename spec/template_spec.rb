require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/responders"

describe Raptor::Template do
  it "raises an error when templates access undefined methods" do
    presenter = Object.new
    resource_name = "posts"
    template_name = "show"
    File.stub(:new) { StringIO.new("<% undefined_method %>") }

    expect do
      Raptor::Template.new(presenter, resource_name, template_name).render
    end.to raise_error(NameError,
                       /undefined local variable or method `undefined_method'/)
  end
end

