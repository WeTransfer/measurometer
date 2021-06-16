require 'spec_helper'

RSpec.describe Measurometer do
  RSpec::Matchers.define :include_counter_or_measurement_named do |named|
    match do |actual|
      actual.any? do |e|
        e[0] == named && e[1] > 0
      end
    end
  end

  before(:each) { Measurometer.drivers.clear }
  after(:each) { Measurometer.drivers.clear }

  it 'has a version number' do
    expect(Measurometer::VERSION).not_to be nil
  end

  describe '.drivers' do
    let(:driver) { Object.new }

    it 'allows adding and removing a driver' do
      expect(Measurometer.drivers).not_to include(driver)

      Measurometer.drivers << driver
      expect(Measurometer.drivers).to include(driver)

      Measurometer.drivers.delete(driver)
      expect(Measurometer.drivers).not_to include(driver)
    end

    it 'does not add the same driver twice' do
      Measurometer.drivers.clear
      3.times { Measurometer.drivers << driver }
      expect(Measurometer.drivers.length).to eq(1)
    end
  end

  describe '.add_distribution_value' do
    it 'converts the metric name to a String before passing it to the driver' do
      driver = double
      expect(driver).to receive(:add_distribution_value).with('bar_intensity', 114.4, {})

      Measurometer.drivers << driver
      result = Measurometer.add_distribution_value(:bar_intensity, 114.4)
      expect(result).to be_nil
    end

    it 'accepts tags and passes them through' do
      driver = double
      expect(driver).to receive(:add_distribution_value).with('bar_intensity', 114.4, host: 'server1')

      Measurometer.drivers << driver
      result = Measurometer.add_distribution_value(:bar_intensity, 114.4, host: 'server1')
      expect(result).to be_nil
    end
  end

  describe '.increment_counter' do
    it 'increments by 1 by default and converts the counter name to a String before passing it to the driver' do
      driver = double
      expect(driver).to receive(:increment_counter).with('barness', 1, {})

      Measurometer.drivers << driver
      result = Measurometer.increment_counter(:barness)
      expect(result).to be_nil
    end

    it 'passes the increment to the driver' do
      driver = double
      expect(driver).to receive(:increment_counter).with('barness', 123, {})

      Measurometer.drivers << driver
      result = Measurometer.increment_counter(:barness, 123)
      expect(result).to be_nil
    end

    it 'passes tags to the driver' do
      driver = double
      expect(driver).to receive(:increment_counter).with('barness', 123, tag1: 11, tag2: 22)

      Measurometer.drivers << driver
      result = Measurometer.increment_counter(:barness, 123, tag1: 11, tag2: 22)
      expect(result).to be_nil
    end
  end

  describe '.set_gauge' do
    it 'converts the gauge name to a String before passing it to the driver' do
      driver = double
      expect(driver).to receive(:set_gauge).with('fooeyness', 456, {})

      Measurometer.drivers << driver
      result = Measurometer.set_gauge(:fooeyness, 456)
      expect(result).to be_nil
    end

    it 'passes tags to the driver' do
      driver = double
      expect(driver).to receive(:set_gauge).with('fooeyness', 123, tag1: 11, tag2: 22)

      Measurometer.drivers << driver
      result = Measurometer.set_gauge(:fooeyness, 123, tag1: 11, tag2: 22)
      expect(result).to be_nil
    end
  end

  describe '.instrument' do
    it 'preserves the return value of the block even if one of the drivers swallows it' do
      bad_driver = Object.new
      def bad_driver.instrument(_blk)
        yield
        nil # Be nasty
      end

      Measurometer.drivers << bad_driver
      instrument_result = Measurometer.instrument('foo') do
        :block_result
      end
      Measurometer.drivers.delete(bad_driver)

      expect(instrument_result).to eq(:block_result)
    end

    it 'converts the block name to a String before passing it to the instrumenters' do
      instrumentation_driver = Object.new
      def instrumentation_driver.instrument(block_name)
        raise 'Block name must be a string' unless block_name.is_a?(String)
        yield
      end

      Measurometer.drivers << instrumentation_driver
      instrument_result = Measurometer.instrument(:foo) do
        :block_result
      end
      Measurometer.drivers.delete(instrumentation_driver)

      expect(instrument_result).to eq(:block_result)
    end
  end

  it 'sources instrumentation to a driver' do
    driver_class = Class.new do
      attr_accessor :timings, :counters, :distributions, :gauges
      def instrument(block_name)
        s = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield.tap do
          delta = Process.clock_gettime(Process::CLOCK_MONOTONIC) - s
          @timings ||= []
          @timings << [block_name, delta * 1000]
        end
      end

      def add_distribution_value(value_path, value, _tags = {})
        @distributions ||= []
        @distributions << [value_path, value]
      end

      def increment_counter(value_path, value, _tags = {})
        @counters ||= []
        @counters << [value_path, value]
      end

      def set_gauge(value_path, value, _tags = {})
        @gauges ||= []
        @gauges << [value_path, value]
      end
    end

    instrumenter = driver_class.new
    Measurometer.drivers << instrumenter

    Measurometer.instrument('something_amazing.foo') do
      sleep(rand / 4)
      Measurometer.instrument('something_amazing.subtask') do
        sleep(rand / 9)
        Measurometer.increment_counter('something_amazing.conflagrations_triggered')
        Measurometer.increment_counter('something_amazing.subtasks_performed', 1)
      end
      Measurometer.instrument('something_amazing.another_subtask') do
        sd = rand / 9
        sleep(sd)
        Measurometer.add_distribution_value('something_amazing.another_subtask.sleep_durations', sd)
      end
      Measurometer.set_gauge('some.gauge', 42)
      :task_finished
    end

    Measurometer.drivers.delete(instrumenter)

    expect(instrumenter.counters).to include_counter_or_measurement_named('something_amazing.subtasks_performed')
    expect(instrumenter.counters).to include_counter_or_measurement_named('something_amazing.conflagrations_triggered')
    expect(instrumenter.distributions).to include_counter_or_measurement_named('something_amazing.another_subtask.sleep_durations')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.subtask')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.another_subtask')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.foo')
    expect(instrumenter.gauges).to include_counter_or_measurement_named('some.gauge')
  end
end
