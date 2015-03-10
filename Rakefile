require "bundler/gem_tasks"

# append to the release task to tag this as 'release',
# meaning it is the most recent release
task :release do |t|
  sh "git tag -a -f release -m \"Update release tag for #{Bundler::GemHelper.gemspec.version}\""
end

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

Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
end

task :default => [ :tests, :yard ]
task :tests => [ :spec, :features ]
