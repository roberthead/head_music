# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -r head_music.rb"
end
