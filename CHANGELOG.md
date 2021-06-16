# 1.3.0

* Adds support to set a tag on Appsignal in `add_distribution_value` as well (in addition to gauges and counters)

# 1.2.0

* Adds support to set a tag on Appsignal in methods `increment_counter` and `set_gauge`

**Warning**: this version introduced a breaking change. It will be necessary to
add the new 3rd argument to the methods `#increment_counter` and `#set_gauge` if you
have a custom driver defined in your application, for example:

```diff
-class CustomDriver
-  def increment_counter(counter_name, by)
-  def set_gauge(gauge_name, value)
+class CustomDriver
+  def increment_counter(counter_name, by, _tags={})
+  def set_gauge(gauge_name, value, _tags={})
```

# 1.1.1

* Automatically convert metric and instrumentation block names to Strings, since i.e.
  Appsignal cannot deal with Symbol names for those.

# 1.1.0

* Ensure #increment_counter provides the default increment of 1 to the drivers

# 1.0.0

* Initial release
