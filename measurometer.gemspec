
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'measurometer/version'

Gem::Specification.new do |spec|
  spec.name          = 'measurometer'
  spec.version       = Measurometer::VERSION
  spec.authors       = ['Julik Tarkhanov']
  spec.email         = ['me@julik.nl']

  spec.summary       = 'Minimum viable API for instrumentation in libraries'
  spec.description   = 'Minimum viable API for instrumentation in libraries. Source metrics from your libraries to Measurometer, pick them up on the other end in the application, centrally.'
  spec.homepage      = 'https://github.com/WeTransfer/measurometer'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(/\.png$/)
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'wetransfer_style', '0.5.0'
end
