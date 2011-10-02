require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/inference"

describe Raptor::InferenceSources do
  let(:record) { stub }
  let(:params) { stub }
  let(:request) { stub(:params => params,
                       :path_info => '/foo/5',
                       :request_method => "GET") }
  let(:route_path) { '/foo/:id' }
  let(:sources) { Raptor::InferenceSources.new(request, route_path) }

  it "infers http method" do
    sources.to_hash.fetch(:http_method).should == "GET"
  end

  it "infers path" do
    sources.to_hash.fetch(:path).should == "/foo/5"
  end

  it "infers request params" do
    sources.to_hash.fetch(:params).should == params
  end

  it "infers IDs from paths" do
    sources.to_hash.fetch(:id).should == 5
  end

  it "infers record" do
    sources.with_record(record).to_hash.fetch(:record).should == record
  end

  it "infers the whole request" do
    sources.to_hash.fetch(:request).should == request
  end

  it "infers other model objects"
end

