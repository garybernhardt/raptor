require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/injector"

describe Raptor::Injectables::Request do
  let(:req) do
    request("POST", "/the/path", StringIO.new("param=value"))
  end
  subject { Raptor::Injectables::Request.new(req) }

  it "injects the whole request" do
    subject.sources.fetch(:request).call.should == req
  end

  it "injects the HTTP method" do
    subject.sources.fetch(:http_method).call.should == "POST"
  end

  it "injects the path" do
    subject.sources.fetch(:path).call.should == "/the/path"
  end

  it "injects request params" do
    subject.sources.fetch(:params).call.should == {"param" => "value"}
  end
end

describe Raptor::Injectables::RouteVariable do
  it "injects IDs from paths" do
    req = request("GET", "/posts/5")
    injectable = Raptor::Injectables::RouteVariable.new(req, "/posts/:id")
    injectable.sources.fetch(:id).call.should == "5"
  end

  it "injects the correct variables when there are multiple" do
    req = request("GET", "/users/3/posts/4")
    injectable = Raptor::Injectables::RouteVariable.new(
      req, "/users/:user_id/posts/:post_id")
    injectable.sources.fetch(:user_id).call.should == "3"
    injectable.sources.fetch(:post_id).call.should == "4"
  end
end

describe Raptor::Injectables::All do
  let(:req) do
    request("GET", "/posts/5")
  end
  subject { Raptor::Injectables::All.new(req, "/posts/:id") }

  it "injects request injectables" do
    subject.sources.fetch(:request).call.should == req
  end

  it "injects route variable injectables" do
    subject.sources.fetch(:id).call.should == "5"
  end
end

