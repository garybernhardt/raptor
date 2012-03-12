require "rack"
require_relative "spec_helper"
require "raptor"

describe Raptor::Injector do
  def method_taking_id(id); id; end
  def method_taking_splat(*); 'nothing'; end
  def method_taking_nothing; 'nothing' end
  def method_taking_only_a_block(&block); 'nothing' end
  def method_taking_subject(subject); subject; end
  def method_taking_optional_id(id = 0); id; end
  def method_taking_optional_arg(arg = 0); arg; end

  let(:injector) do
    Raptor::Injector.new([Raptor::Injectables::Fixed.new(:id, 5)])
  end

  it "injects required arguments for delegate methods" do
    injector.call(method(:method_taking_id)).should == 5
  end

  it "injects [] when the method only takes optional parameters" do
    injector.call(method(:method_taking_splat)).should == 'nothing'
  end

  it "injects [] when the method takes nothing" do
    injector.call(method(:method_taking_nothing)).should == 'nothing'
  end

  it "injects [] when the method takes only a block" do
    injector.call(method(:method_taking_only_a_block)).should == 'nothing'
  end

  it "injects required arguments even if they are optional" do
    injector.call(method(:method_taking_optional_id)).should == 5
  end

  it "uses the default value if the argument was optional and nothing was passed for it" do
    injector.call(method(:method_taking_optional_arg)).should == 0
  end

  it "injects arguments from initialize for the new method" do
    method = ObjectWithInitializerTakingId.method(:new)
    injector.call(method).id.should == 5
  end

  it "throws an error when no source is found for an argument" do
    klass = Class.new { def f(unknown_argument); end }
    expect do
      injector.call(klass.new.method(:f))
    end.to raise_error(Raptor::UnknownInjectable)
  end

  it "injects the subject once it's been given one" do
    subject = stub
    method = method(:method_taking_subject)
    injector_with_subject = injector.add_subject(subject)
    injector_with_subject.call(method).should == subject
  end

  it "injects requests once it's been given one" do
    def method_taking_request(rack_request); rack_request; end
    request = stub
    method = method(:method_taking_request)
    injector_with_request = injector.add_request(request)
    injector_with_request.call(method).should == request
  end

  it "injects route variables once it's been given the route path" do
    def method_taking_id(id); id; end
    request = stub(:path_info => "/posts/5")
    method = method(:method_taking_id)
    injector_with_route_path = injector.add_route_path(request, "/posts/:id")
    injector_with_route_path.call(method).should == "5"
  end

  context "custom injectables" do
    before do
      module WithInjectables
        module Injectables
          class Fruit
            def sources(injector)
              {:watermelon => lambda { "fruity" } }
            end
          end
        end
      end

      module WithoutInjectables
      end
    end

    it "injects custom injectables" do
      def takes_watermelon(watermelon); watermelon; end
      injector = Raptor::Injector.for_app_module(WithInjectables)
      injector.call(method(:takes_watermelon)).should == "fruity"
    end

    it "doesn't require the Injectables module to exist" do
      def takes_request(rack_request); rack_request; end
      request = stub(:request)
      injector = Raptor::Injector.for_app_module(WithoutInjectables)
      injector = injector.add_request(request)
      injector.call(method(:takes_request)).should == request
    end
  end
end

class ObjectWithInitializerTakingId
  attr_reader :id
  def initialize(id)
    @id = id
  end
end

