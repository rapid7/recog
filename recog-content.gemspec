# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'recog-content'
  s.version     = "0.0.1"
  s.required_ruby_version = '>= 2.1'
  s.authors     = [
    'Rapid7 Research'
  ]
  s.email       = [
    'research@rapid7.com'
  ]
  s.homepage    = "https://www.github.com/rapid7/recog"
  s.summary     = %q{Network service fingerprint database and utilities}
  s.description = %q{
    recog-content is the Recog fingerprint database and management utilities. Recog is a framework for
    identifying products, services, operating systems, and hardware by matching fingerprints against
    datareturned from various network probes. Recog makes it simply to extract useful information from
    web server banners, snmp system description fields, and a whole lot more.
  }.gsub(/\s+/, ' ').strip

  s.files         = %w(Gemfile Rakefile COPYING LICENSE README.md recog-content.gemspec .yardopts) +
                    Dir.glob('bin/*') +
                    Dir.glob('features**/*') +
                    Dir.glob('xml/*')

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.executables    = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }

  # ---- Dependencies ----

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  if RUBY_PLATFORM =~ /java/
    # markdown formatting for yard
    s.add_development_dependency 'kramdown'
  else
    # markdown formatting for yard
    s.add_development_dependency 'redcarpet'
  end
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'simplecov'

  s.add_runtime_dependency 'recog'
end
