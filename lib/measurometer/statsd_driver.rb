module Measurometer
  class StatsdDriver
    attr_accessor :statsd_client

    MONOTONIC_AVAILABLE = defined?(Process::CLOCK_MONOTONIC)

    def initialize(ruby_statsd_client)
      @statsd_client = ruby_statsd_client
    end

    def instrument(action_name)
      s = gettime
      yield.tap do
        delta_fractional_s = gettime - s
        millis = (delta_fractional_s * 1000).to_i
        @statsd_client.timing(action_name, millis)
      end
    end

    def increment_counter(counter_name, by)
      @statsd_client.increment(counter_name, by)
    end

    def add_distribution_value(key_path, value)
      @statsd_client.count(key_path, value)
    end

    def set_gauge(gauge_name, value)
      @statsd_client.gauge(gauge_name, value)
    end

    private

    def gettime
      MONOTONIC_AVAILABLE ? Process.clock_gettime(Process::CLOCK_MONOTONIC) : Time.now.to_f
    end
  end
end
