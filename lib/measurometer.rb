require 'measurometer/version'
require 'set'

module Measurometer
  @drivers = Set.new
  autoload :StatsdDriver, 'measurometer/statsd_driver'

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
    #
    # The driver must support the same interface as the Measurometer class
    # itself, minus the `drivers` method.
    #
    # Note that this method does not return a copy of the drivers, it returns
    # the mutable Set itself
    #
    # @return [Set]
    def drivers
      @drivers
    end

    # Runs a given block within a cascade of `instrument` blocks of all the
    # added drivers.
    #
    #   Measurometer.instrument('do_foo') { compute! }
    #
    # unfolds to
    #
    #   Appsignal.instrument('do_foo') do
    #     StatsdDriver#instrument('do_foo') do
    #       compute!
    #     end
    #   end
    #
    # @param block_name[String] under which path to push the metric
    # @param tags[Hash<Symbol->String>] any tags for the metric
    # @param blk[#call] the block to instrument
    # @return [Object] the return value of &blk
    def instrument(block_name, **tags, &blk)
      return yield if @drivers.empty? # The block wrapping business is not free
      blk_return_value = nil
      blk_with_capture = -> { blk_return_value = blk.call }
      @drivers.inject(blk_with_capture) { |outer_block, driver|
        -> {
          driver.instrument(block_name, **tags, &outer_block)
        }
      }.call
      blk_return_value
    end

    # Adds a distribution value (sample) under a given path
    #
    # @param value_path[String] under which path to push the metric
    # @param value[Numeric] distribution value
    # @param tags[Hash<Symbol->String>] any tags for the metric
    # @return nil
    def add_distribution_value(value_path, value, **tags)
      @drivers.each { |d| d.add_distribution_value(value_path, value, **tags) }
      nil
    end

    # Increment a named counter under a given path
    #
    # @param counter_path[String] under which path to push the metric
    # @param by[Integer] the counter increment to apply
    # @param tags[Hash<Symbol->String>] any tags for the metric
    # @return nil
    def increment_counter(counter_path, by = 1, **tags)
      @drivers.each { |d| d.increment_counter(counter_path, by, **tags) }
      nil
    end

    # Set a global single named value (gauge)
    #
    # @param gauge_name[String] under which path to push the metric
    # @param value[Integer] the absolute value of the gauge
    # @param tags[Hash<Symbol->String>] any tags for the metric
    # @return nil
    def set_gauge(gauge_name, value, **tags)
      @drivers.each { |d| d.set_gauge(gauge_name, value, **tags) }
      nil
    end
  end
end
