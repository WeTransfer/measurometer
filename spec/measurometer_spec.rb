require "spec_helper"

RSpec.describe Measurometer do
  RSpec::Matchers.define :include_counter_or_measurement_named do |named|
    match do |actual|
      actual.any? do |e|
        e[0] == named && e[1] > 0
      end
    end
  end

  it "has a version number" do
    expect(Measurometer::VERSION).not_to be nil
  end

  describe '.drivers' do
    before(:each) { Measurometer.drivers.clear }
    after(:each) { Measurometer.drivers.clear }
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

  describe '.instrument' do
    it 'preserves the return value of the block even if one of the drivers swallows it' do
      bad_driver = Object.new
      def bad_driver.instrument(blk)
        result = yield
        nil # Be nasty
      end

      Measurometer.drivers << bad_driver
      instrument_result = Measurometer.instrument('foo') do
        :block_result
      end
      Measurometer.drivers.delete(bad_driver)

      expect(instrument_result).to eq(:block_result)
    end
  end

  it 'sources instrumentation to a driver' do
    driver_class = Class.new do
      attr_accessor :timings, :counters, :distributions
      def instrument(block_name)
        s = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield.tap do
          delta = Process.clock_gettime(Process::CLOCK_MONOTONIC) - s
          @timings ||= []
          @timings << [block_name, delta * 1000]
        end
      end

      def add_distribution_value(value_path, value)
        @distributions ||= []
        @distributions << [value_path, value]
      end

      def increment_counter(value_path, value)
        @counters ||= []
        @counters << [value_path, value]
      end
    end

    instrumenter = driver_class.new
    Measurometer.drivers << instrumenter


    instrument_result = Measurometer.instrument('something_amazing.foo') do
      sleep(rand / 4)
      Measurometer.instrument('something_amazing.subtask') do
        sleep(rand / 9)
        Measurometer.increment_counter('something_amazing.subtasks_performed', 1)
      end
      Measurometer.instrument('something_amazing.another_subtask') do
        sd = rand / 9
        sleep(sd)
        Measurometer.add_distribution_value('something_amazing.another_subtask.sleep_durations', sd)
      end
      :task_finished
    end

    Measurometer.drivers.delete(instrumenter)

    expect(instrumenter.counters).to include_counter_or_measurement_named('something_amazing.subtasks_performed')
    expect(instrumenter.distributions).to include_counter_or_measurement_named('something_amazing.another_subtask.sleep_durations')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.subtask')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.another_subtask')
    expect(instrumenter.timings).to include_counter_or_measurement_named('something_amazing.foo')
  end
end
