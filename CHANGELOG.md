# 1.2.0

* Adds support to set a tag on Appsignal in methods `increment_counter` and `set_gauge`

# 1.1.1

* Automatically convert metric and instrumentation block names to Strings, since i.e.
  Appsignal cannot deal with Symbol names for those.

# 1.1.0

* Ensure #increment_counter provides the default increment of 1 to the drivers

# 1.0.0

* Initial release
