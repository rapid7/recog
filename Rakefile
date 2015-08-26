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

task :default => [ :tests, :yard ]
task :tests => [ :spec ]
