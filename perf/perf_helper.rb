require 'benchmark'

def benchmark(spec_name, &block)
  time = Benchmark.realtime(&block)
  puts "#{spec_name}: #{time}"
end

