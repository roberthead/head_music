require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

# The block runs when the task does, just before rspec is launched.
RSpec::Core::RakeTask.new(:spec) { ENV["COVERAGE"] = "true" }

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

namespace :music_xml do
  desc "Regenerate the MuseScore 4 and timewise fixtures (spec/fixtures/notation/music_xml/); MSCORE overrides the mscore path"
  task :musescore_fixtures do
    $LOAD_PATH.unshift File.expand_path("lib", __dir__)
    require "head_music"
    require "rspec/core"
    require "shellwords"
    require_relative "spec/support/musescore"

    with_final_newline = ->(path) { File.write(path, File.read(path).chomp + "\n") }
    MuseScoreFixtures.names.each do |name|
      rendered = MuseScoreFixtures.path(name, "head_music")
      File.write(rendered, MuseScoreFixtures.musicxml(name))
      MuseScore.convert_file(rendered, MuseScoreFixtures.path(name, "musescore4"))
      with_final_newline.call(MuseScoreFixtures.path(name, "musescore4"))
      puts "Wrote #{name}"
    end

    stylesheet = "/Applications/Dorico 6.app/Contents/Resources/musicxml/parttime.xsl"
    next puts("Skipped the timewise fixtures: #{stylesheet} not found") unless File.exist?(stylesheet)

    MuseScoreFixtures::TIMEWISE.each do |name|
      timewise = MuseScoreFixtures.path(name, "timewise")
      sh "xsltproc --nonet --novalid #{stylesheet.shellescape} #{MuseScoreFixtures.path(name, "head_music").shellescape} > #{timewise.shellescape}"
      with_final_newline.call(timewise)
      puts "Wrote #{name} timewise"
    end
  end
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
    sh({"COVERAGE" => nil}, "bundle exec ruby bin/guide_grade_corpus.rb #{path}")
    puts "Wrote #{path}"
  end
end
