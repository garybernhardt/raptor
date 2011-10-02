require './spec/spec_helper'

describe Raptor::RouteCriteria do
  it "matches if the requirement matches" do
    match?(stub(:match? => true)).should be_true
  end

  it "doesn't match if the requirement doesn't" do
    match?(stub(:match? => false)).should be_false
  end

  def match?(requirement)
    criteria = Raptor::RouteCriteria.new("/url", [requirement])
    criteria.match?("/url", {})
  end

  it "infers requirement arguments" do
    requirement = Module.new do
      def self.match?(path)
        path == "/the/path"
      end
    end
    inference_sources = {:path => "/the/path"}
    criteria = Raptor::RouteCriteria.new("/url", [requirement])
    criteria.match?("/url", inference_sources).should be_true
  end
end

