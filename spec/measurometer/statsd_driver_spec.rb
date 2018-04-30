require 'spec_helper'

describe 'Measurometer::StatsdDriver' do
  after(:each) do
    Measurometer.drivers.clear
  end

  it 'passes metrics to the contained Statsd client' do
    statsd = spy('Statsd')
    Measurometer.drivers << Measurometer::StatsdDriver.new(statsd)

    Measurometer.instrument('some_block.x') do
      sleep 0.21
    end

    Measurometer.set_gauge('app.some_gauge', 42)
    Measurometer.increment_counter('app.some_counter', 2)
    Measurometer.add_distribution_value('app.some_sample', 42)

    expect(statsd).to have_received(:timing) {|block_name, timing_millis|
      expect(block_name).to eq('some_block.x')
      expect(timing_millis).to be_within(20).of(200)
    }

    expect(statsd).to have_received(:increment).with('app.some_counter', 2)
    expect(statsd).to have_received(:count).with('app.some_sample', 42)
  end
end
