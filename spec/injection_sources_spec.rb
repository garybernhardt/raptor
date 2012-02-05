require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/injector"

describe Raptor::InjectionSources do
  let(:params) { stub }
  let(:request) { stub(:params => params,
                       :path_info => '/5',
                       :request_method => "GET") }
  let(:route_path) { '/:id' }
  let(:sources) { Raptor::InjectionSources.new(request, route_path) }

  it "injects http method" do
    sources.to_hash.fetch(:http_method).should == "GET"
  end

  it "injects path" do
    sources.to_hash.fetch(:path).should == "/5"
  end

  it "injects request params" do
    sources.to_hash.fetch(:params).should == params
  end

  it "injects IDs from paths" do
    sources.to_hash.fetch(:id).should == 5
  end

  it "injects the whole request" do
    sources.to_hash.fetch(:request).should == request
  end

  it "injects other model objects"
end

