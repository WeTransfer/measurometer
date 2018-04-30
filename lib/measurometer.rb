require 'measurometer/version'
require 'set'

module Measurometer
  @drivers = Set.new

  class << self
    # Permits adding instrumentation drivers. Measurometer is 1-1 API
    # compatible with Appsignal, which we use a lot. So to magically
    # obtain all Appsignal instrumentation, add the Appsignal module
    # as a driver.
    #
    #   Measurometer.drivers << Appsignal
    #
    # A driver must be reentrant and thread-safe - it should be possible
    # to have multiple `instrument` calls open from different threads at the
    # same time.
    # The driver must support the same interface as the Measurometer class
    # itself, minus the `drivers` and `instrument_instance_method` methods.
    #
    # @return Array
    def drivers
      @drivers
    end

    # Runs a given block within a cascade of `instrument` blocks of all the
    # added drivers.
    #
    #   Measurometer.instrument('do_foo') { compute! }
    #
    # unfolds to
    #   Appsignal.instrument('do_foo') do
    #     Statsd.timing('do_foo') do
    #       compute!
    #     end
    #   end
    #
    # A driver must be reentrant and thread-safe - it should be possible
    # to have multiple `instrument` calls open from different threads at the
    # same time.
    # The driver must support the same interface as the Measurometer class
    # itself, minus the `drivers` and `instrument_instance_method` methods.
    #
    # @param block_name[String] under which path to push the metric
    # @param blk[#call] the block to instrument
    # @return [Object] the return value of &blk
    def instrument(block_name, &blk)
      return yield if @drivers.empty? # The block wrapping business is not free
      blk_return_value = nil
      blk_with_capture = -> { blk_return_value = blk.call }
      @drivers.inject(blk_with_capture) { |outer_block, driver|
        -> {
          driver.instrument(block_name, &outer_block)
        }
      }.call
      blk_return_value
    end

    # Adds a distribution value (sample) under a given path
    #
    # @param value_path[String] under which path to push the metric
    # @param value[Numeric] distribution value
    # @return nil
    def add_distribution_value(value_path, value)
      (@drivers || []).each { |d| d.add_distribution_value(value_path, value) }
      nil
    end

    # Increment a named counter under a given path
    #
    # @param counter_path[String] under which path to push the metric
    # @param by[Integer] the counter increment to apply
    # @return nil
    def increment_counter(counter_path, by)
      (@drivers || []).each { |d| d.increment_counter(counter_path, by) }
      nil
    end
  end
end
