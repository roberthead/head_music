require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = ["lib/**/*.rb"]
    t.options = %w[--protected --private]
  end

  desc "Generate documentation and show stats"
  task :doc_stats => :doc do
    sh "yard stats --list-undoc"
  end
rescue LoadError
  # YARD not available
end

begin
  require "bundler/audit/task"
  Bundler::Audit::Task.new
rescue LoadError
  # bundler-audit not available
end

task default: :spec

desc "Run all quality checks (tests, linting, security audit)"
task :quality => [:spec, :standard, "bundle:audit:check"]

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -r head_music.rb"
end

desc "Open coverage report in browser"
task :coverage do
  sh "open coverage/index.html" if File.exist?("coverage/index.html")
end
