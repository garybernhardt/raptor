require 'benchmark'

describe "Loading raptor" do
  it "is fast" do
    benchmark 'RAPTOR_REQUIRE_RUNTIME' do
      require_relative '../lib/raptor'
    end
  end
end

def benchmark(spec_name, &block)
  time = Benchmark.realtime(&block)
  puts "#{spec_name}: #{time}"
end

