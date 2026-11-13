require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new

# One process per core. parallel_tests places each file by its runtime in
# tmp/parallel_runtime_rspec.log, or by its size when that log covers too few
# files, and SimpleCov merges the processes' coverage.
module ParallelSpecs
  extend Rake::FileUtilsExt

  STATUS_FILE = "spec/examples.txt"
  PROCESS_STATUS_FILES = "spec/examples[0-9]*.txt"
  RUNTIME_LOG = "tmp/parallel_runtime_rspec.log"

  def self.run(coverage:)
    narrowed = ENV.key?("SPEC")
    runtimes = narrowed ? runtimes_logged : {}
    rm_f Dir[PROCESS_STATUS_FILES]
    # SimpleCov would merge a serial result from the last ten minutes into the total.
    rm_f %w[coverage/.resultset.json coverage/.resultset.json.lock] if coverage
    # --first-is-1 gives every process a numbered status file to fold back in.
    sh({"COVERAGE" => (coverage ? "true" : nil)}, "bundle exec parallel_rspec --first-is-1 #{ENV.fetch("SPEC", "spec")}")
  ensure
    fold_statuses
    # A narrowed run logs only its own files, which would leave the next full run to group by size.
    write_runtimes(runtimes.merge(runtimes_logged)) if narrowed
  end

  def self.runtimes_logged
    return {} unless File.exist?(RUNTIME_LOG)

    File.readlines(RUNTIME_LOG, chomp: true).to_h { |line| line.rpartition(":").values_at(0, 2) }
  end

  def self.write_runtimes(runtimes)
    File.write(RUNTIME_LOG, runtimes.map { |file, time| "#{file}:#{time}\n" }.join)
  end

  # Keeps `rspec --only-failures` whole after a parallel run.
  def self.fold_statuses
    require "rspec/core"
    files = Dir[PROCESS_STATUS_FILES]
    this_run = files.flat_map { |file| RSpec::Core::ExampleStatusPersister.load_from(file) }
    return if this_run.empty?

    merged = RSpec::Core::ExampleStatusMerger.merge(this_run, RSpec::Core::ExampleStatusPersister.load_from(STATUS_FILE))
    File.write(STATUS_FILE, RSpec::Core::ExampleStatusDumper.dump(merged))
    rm_f files
  end
end

desc "Run the specs in parallel with coverage (SPEC=path narrows the run)"
task(:spec) { ParallelSpecs.run(coverage: true) }

# Coverage slows a run considerably, so validation leaves it to `rake spec` and CI.
desc "Run the specs in parallel without coverage (SPEC=path narrows the run)"
task("spec:without_coverage") { ParallelSpecs.run(coverage: false) }

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

desc "Run only the specs checked against outside tools and files, each missing one skipping with how to set it up"
RSpec::Core::RakeTask.new(:oracles) { ENV["ORACLES"] = "1" }

desc "Run RubyCritic code quality analysis, failing below .rubycritic.yml's minimum score or on any file graded D or F"
task :rubycritic do
  require "json"
  sh "rubycritic"
  report = JSON.parse(File.read("tmp/rubycritic/report.json"))
  failing = report["analysed_modules"].select { |file| %w[D F].include?(file["rating"]) }
  next if failing.empty?

  failing.each { |file| warn format("%s %5.2f %s", file["rating"], file["cost"], file["path"]) }
  abort "RubyCritic graded #{failing.length} file(s) below C"
end

task default: :spec

desc "Run all validation checks (tests without coverage, linting, security audit, code quality)"
task validate: ["spec:without_coverage", :rubocop, "bundle:audit:check", :rubycritic]

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

namespace :mei do
  desc "Regenerate the MEI golden documents (spec/fixtures/notation/mei/)"
  task :golden_fixtures do
    $LOAD_PATH.unshift File.expand_path("lib", __dir__), File.expand_path("spec", __dir__)
    require "rspec/core"
    require "spec_helper"

    MEIFixtures.names.each do |name|
      File.write(MEIFixtures.path(name), MEIFixtures.mei(name))
      puts "Wrote #{name}"
    end
  end

  desc "Regenerate the MuseScore 4 MEI exports (spec/fixtures/notation/mei/musescore/); MSCORE overrides the mscore path"
  task :musescore_fixtures do
    $LOAD_PATH.unshift File.expand_path("lib", __dir__)
    require "head_music"
    require "rspec/core"
    require_relative "spec/support/musescore"

    target_directory = File.expand_path("spec/fixtures/notation/mei/musescore", __dir__)
    FileUtils.mkdir_p(target_directory)
    sources = Dir[File.join(MuseScoreFixtures::DIRECTORY, "*.head_music.musicxml")].sort
    failures = sources.filter_map do |source|
      name = File.basename(source, ".head_music.musicxml")
      target = File.join(target_directory, "#{name}.musescore4.mei")
      MuseScore.convert_file(source, target, timeout: 120)
      File.write(target, File.read(target).chomp + "\n")
      puts "Wrote #{name}"
      nil
    rescue MuseScore::ConversionError => error
      "#{name}: #{error.message}"
    end
    abort "MuseScore failed on:\n#{failures.join("\n")}" if failures.any?
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
