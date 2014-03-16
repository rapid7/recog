# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'recog/version'

Gem::Specification.new do |s|
  s.name        = 'recog'
  s.version     = Recog::VERSION
  s.authors     = [
      'Rapid7 Research'
  ]
  s.email       = [
      'research@rapid7.com'
  ]
  s.homepage    = "https://www.github.com/rapid7/recog"
  s.summary     = %q{Network service fingerprint database, classes, and utilities}
  s.description = %q{
    Recog provides OS fingerprinting of network-connected device by matching their service banners or probe responses to the appropriate pattern database.
    This gem provides a database of network service fingerprints and an set of classes and utilities to manage them.
  }.gsub(/\s+/, ' ').strip

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  # ---- Dependencies ----

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'

  s.add_runtime_dependency 'nokogiri'
end
