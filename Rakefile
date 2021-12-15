require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
    t.pattern = "spec/**/*_spec.rb"
end

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', '-', 'README.md']
end

require 'cucumber'
require 'cucumber/rake/task'

def jruby?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
end

Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty" + (jruby? ? " --tags 'not @jruby-disabled'" : "")
end

task :default => [ :tests, :yard ]
task :tests => [ :spec, :features ]
