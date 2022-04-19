# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'html/pipeline/autolink/version'

Gem::Specification.new do |spec|
  spec.name          = "html-pipeline-autolink"
  spec.version       = Html::Pipeline::Autolink::VERSION
  spec.authors       = ["Jerry Cheung"]
  spec.email         = ["jollyjerry@gmail.com"]
  spec.summary       = %q{HTML::Pipeline::AutolinkFilter}
  spec.description   = %q{Auto links urls in HTML}
  spec.homepage      = "https://github.com/jch/html-pipeline"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rinku", "~> 1.7"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
