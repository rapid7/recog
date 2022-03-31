require "bundler/gem_tasks"

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new do |t|
    t.files = ['bin/*.rb', '-', 'README.md']
end

require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
end

task :default => [ :tests, :yard ]
task :tests => [ :features ]
