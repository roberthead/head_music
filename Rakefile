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
  task doc_stats: :doc do
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

desc "Run RubyCritic code quality analysis"
task :rubycritic do
  sh "rubycritic lib"
end

task default: :spec

desc "Run all validation checks (tests, linting, security audit, code quality)"
task validate: [:spec, :standard, "bundle:audit:check", :rubycritic]

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -r head_music.rb"
end

desc "Open coverage report in browser"
task :coverage do
  sh "open coverage/index.html" if File.exist?("coverage/index.html")
end

namespace :style do
  desc "Regenerate the pinned English guide strings (spec/fixtures/style/english_strings.yml)"
  task :snapshot_english do
    require "yaml"
    $LOAD_PATH.unshift File.expand_path("lib", __dir__)
    require "head_music"

    guides = HeadMusic::Style::Guide::ALL
    items = guides.flat_map(&:guide_items).uniq
    snapshot = %i[en en_GB].to_h do |locale|
      strings = I18n.with_locale(locale) do
        guides.flat_map { |guide| [guide.display_name, guide.instruction] } +
          items.flat_map { |item| [item.name, item.instruction] + item.violation_previews }
      end
      [locale.to_s, strings]
    end

    path = File.expand_path("spec/fixtures/style/english_strings.yml", __dir__)
    File.write(path, snapshot.to_yaml)
    puts "Wrote #{snapshot.values.sum(&:size)} strings to #{path}"
  end

  desc "Regenerate the pinned corpus grading (spec/fixtures/style/corpus_fitness.json)"
  task :snapshot_corpus_fitness do
    path = File.expand_path("spec/fixtures/style/corpus_fitness.json", __dir__)
    sh "bundle exec ruby bin/guide_grade_corpus.rb #{path}"
    puts "Wrote #{path}"
  end
end
