# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'recog/version'

Gem::Specification.new do |s|
  s.name        = 'recog'
  s.version     = Recog::VERSION
  s.required_ruby_version = '>= 2.1'
  s.authors     = [
      'Rapid7 Research'
  ]
  s.email       = [
      'research@rapid7.com'
  ]
  s.homepage    = "https://www.github.com/rapid7/recog"
  s.summary     = %q{Network service fingerprint database, classes, and utilities}
  s.license     = 'BSD-2-Clause'
  s.description = %q{
    Recog is a framework for identifying products, services, operating systems, and hardware by matching
    fingerprints against data returned from various network probes. Recog makes it simply to extract useful
    information from web server banners, snmp system description fields, and a whole lot more.
  }.gsub(/\s+/, ' ').strip

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  # ---- Dependencies ----

  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'yard', '~> 0.8'
  if RUBY_PLATFORM =~ /java/
    # markdown formatting for yard
    s.add_development_dependency 'kramdown', '~> 1.8'
  else
    # markdown formatting for yard
    s.add_development_dependency 'redcarpet', '~> 3.3'
  end
  s.add_development_dependency 'aruba', '~> 0.5.3'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'regexp_parser', '~> 0.3'

  s.add_runtime_dependency 'nokogiri', '~> 1.6'
end
