# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stark/version'

Gem::Specification.new do |spec|
  spec.name          = "stark"
  spec.version       = Stark::VERSION
  spec.authors       = ["gkentr"]
  spec.email         = ["georgios@wearhacks.com"]

  spec.summary       = %q{This is a tool which can be used to speed up the course creation process for the Stark Labs platform.}
  spec.description   = %q{For a thorough description you can take a look at https://github.com/wearhacks/stark_course_generator/edit/master/README.md .}
  spec.homepage      = "https://github.com/wearhacks/stark_course_generator"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # spec.add_dependency 
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
