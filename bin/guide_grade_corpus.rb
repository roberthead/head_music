#!/usr/bin/env ruby
# Grades a fixed corpus of voices against every registered guide and writes one
# JSON row per (corpus entry, guide).
#
#   bundle exec ruby bin/guide_grade_corpus.rb out.json
#
# Written to run on both sides of a grading change: the corpus and the grading
# live in spec/support/guide_grading.rb, and this script is only the file-writing
# wrapper around them. `rake style:snapshot_corpus_fitness` writes the pinned
# snapshot; this script exists for capturing a second one to diff against it.
#
# The invariant is that each column is the same measurement made again -- not
# that the file is never edited. When a change needs a seam this script does not
# yet have, the edit lands BEFORE both captures and is proven a no-op by diffing
# a capture from either side of it.
#
# Loading the fixture exercises means loading spec_helper, which starts
# SimpleCov and rewrites coverage/.last_run.json. That file is restored on the
# way out, so a later `bundle exec rake` measures against the baseline it had.

require "json"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift File.join(ROOT, "lib"), File.join(ROOT, "spec")

COVERAGE_BASELINE = File.join(ROOT, "coverage", ".last_run.json")
SAVED_BASELINE = File.exist?(COVERAGE_BASELINE) ? File.read(COVERAGE_BASELINE) : nil
at_exit do
  if SAVED_BASELINE
    File.write(COVERAGE_BASELINE, SAVED_BASELINE)
  elsif File.exist?(COVERAGE_BASELINE)
    File.delete(COVERAGE_BASELINE)
  end
end

require "head_music"
require "flow_context"
require "spec_helper"

rows = GuideGrading.rows

# One row per line: valid JSON, but a third the size of a pretty-printed dump
# and diffable a row at a time, which is how the snapshot is read.
File.write(ARGV.fetch(0), "[\n#{rows.map { |row| JSON.generate(row) }.join(",\n")}\n]\n")
warn "rows=#{rows.length} guides=#{HeadMusic::Style::Guide::ALL.length} " \
     "errors=#{rows.count { |row| row[:error] }}"
