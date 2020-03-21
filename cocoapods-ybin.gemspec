# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-ybin/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-ybin'
  spec.version       = CocoapodsYbin::VERSION
  spec.authors       = ['monetking']
  spec.email         = ['houmanager@qq.com']
  spec.description   = %q{cocoapods-ybin is a plug-in for link source and binary.}
  spec.summary       = %q{link source and binary.}
  spec.homepage      = 'https://github.com/monetking/cocoapods-ybin.git'
  spec.license       = 'MIT'

  # spec.files         = `git ls-files`.split($/)
  spec.files         = Dir["lib/**/*.rb", "spec/**/*.rb"] + %w{README.md LICENSE.txt }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'cocoapods'
  spec.add_dependency 'cocoapods-generate'
  spec.add_dependency 'parallel'
end
