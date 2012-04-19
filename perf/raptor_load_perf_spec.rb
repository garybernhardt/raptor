require_relative 'perf_helper'

describe "Loading raptor" do
  it "is fast" do
    benchmark 'RAPTOR_REQUIRE_RUNTIME' do
      require_relative '../lib/raptor'
    end
  end
end

