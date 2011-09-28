require './spec/spec_helper'

describe Raptor::InferenceSources do
  before do
    @params = stub
    @request = stub(:params => @params, :path_info => '/foo/5')
    @route_path = '/foo/:id'
    @sources = Raptor::InferenceSources.new(@request, @route_path).to_hash
  end

  it "infers path" do
    @sources.fetch(:path).should == "/foo/5"
  end

  it "infers request params" do
    @sources.fetch(:params).should == @params
  end

  it "infers IDs from paths" do
    @sources.fetch(:id).should == 5
  end

  it "infers model objects"
end

