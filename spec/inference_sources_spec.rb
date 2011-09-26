require './spec/spec_helper'
require 'mocha'

describe Raptor::InferenceSources do
  before do
    @params = stub
    @request = stub(:params => @params)
    @route_path = '/foo/:id'
    @path = '/foo/5'
    @sources = Raptor::InferenceSources.new(@request,
                                            @route_path,
                                            @path).sources
  end

  it "infers request params" do
    @sources.fetch(:params).must_equal @params
  end

  it "infers IDs from paths" do
    @sources.fetch(:id).must_equal 5
  end
end

