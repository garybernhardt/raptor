require_relative 'perf_helper'
require_relative '../lib/raptor'
require_relative '../spec/spec_helper'

module Ping
  App = Raptor::App.new(self) do
    path "ping" do
      index :to => 'Ping.ping'
    end
  end

  class Ping
    def self.ping
      'ping'
    end
  end

  module Presenters
    class PingList
      attr_reader :subject
      def initialize(subject); @subject = subject; end
    end
  end
end

describe "ping" do
  it "is fast" do
    Ping::App.call(env('GET', '/ping/')).inspect
    benchmark 'RAPTOR::PING_RUNTIME' do
      1000.times do
        Ping::App.call(env('GET', '/ping/')).inspect
      end
    end
  end
end

