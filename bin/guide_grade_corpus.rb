#!/usr/bin/env ruby
# Grades a fixed corpus of voices against every registered guide and writes one
# JSON row per (corpus entry, guide).
#
#   bundle exec ruby bin/guide_grade_corpus.rb out.json
#
# Written to run UNMODIFIED on both sides of a grading change, including at a
# merge-base where `assessable?` does not exist and the harmony guides raise on
# a solo voice. It therefore asks only what both trees can answer, and records a
# raised error as a value rather than letting it stop the run.
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
require "composition_context"
require "spec_helper"

LADDER = %w[D4 F4 E4 G4 F4 A4 G4 F4].freeze
REPEATED = Array.new(8, "E4").freeze
CANTUS = %w[D4 F4 E4 D4 G4 F4 E4 D4].freeze

def composition(key: "D dorian")
  HeadMusic::Content::Composition.new(name: "corpus", key_signature: key)
end

def place(voice, pitches)
  pitches.each_with_index { |pitch, bar| voice.place("#{bar + 1}:1", :whole, pitch) }
  voice
end

# A voice alone in its composition: no companion, so the harmony guides have
# nothing to be set against.
def solo(pitches)
  place(composition.add_voice(role: :counterpoint), pitches)
end

# A counterpoint voice with a companion, which may itself be empty.
def accompanied(pitches, companion_pitches)
  comp = composition
  place(comp.add_voice(role: "Cantus Firmus"), companion_pitches)
  place(comp.add_voice(role: :counterpoint), pitches)
end

def corpus
  entries = []
  (0..8).each { |n| entries << ["solo-ascending-#{n}", solo(LADDER.first(n))] }
  (0..8).each { |n| entries << ["solo-repeated-#{n}", solo(REPEATED.first(n))] }
  [0, 1, 2, 4, 8].each { |n| entries << ["against-empty-#{n}", accompanied(LADDER.first(n), [])] }
  [0, 1, 2, 4, 8].each { |n| entries << ["against-cantus-#{n}", accompanied(LADDER.first(n), CANTUS)] }

  %w[
    fux_cantus_firmus_examples clendinning_cantus_firmus_examples
    schoenberg_cantus_firmus_examples davis_and_lybbert_cantus_firmus_examples
    fux_cantus_firmus_examples_with_errors fux_first_species_examples
    clendinning_first_species_examples davis_and_lybbert_first_species_examples
  ].each do |source|
    Array(send(source)).each_with_index do |context, index|
      context.composition.voices.each_with_index do |voice, position|
        entries << ["#{source}-#{index}-v#{position}", voice]
      end
    end
  end
  entries
end

# Everything here must be answerable on both sides of the change.
def grade(guide, voice)
  assessment = HeadMusic::Style::GuideAssessment.new(guide, voice)
  items = assessment.respond_to?(:guide_item_assessments) ? assessment.guide_item_assessments : assessment.annotations
  {
    fitness: assessment.fitness.round(12),
    adherent: assessment.adherent?,
    message_count: assessment.messages.length,
    item_count: items.length,
    assessable: assessment.respond_to?(:assessable?) ? assessment.assessable? : nil,
    failed_gates: items.select { |item| item.gate? && !item.adherent? }.map { |item| item.guideline.name.split("::").last }.sort
  }
rescue => error
  {fitness: nil, adherent: nil, message_count: nil, item_count: nil, assessable: nil,
   failed_gates: [], error: error.class.name}
end

rows = corpus.flat_map do |label, voice|
  HeadMusic::Style::Guide::ALL.map do |guide|
    {
      corpus: label,
      notes: voice.notes.length,
      guide: HeadMusic::Style::Guide.key_for(guide)
    }.merge(grade(guide, voice))
  end
end

File.write(ARGV.fetch(0), JSON.pretty_generate(rows))
warn "rows=#{rows.length} corpus=#{corpus.length} guides=#{HeadMusic::Style::Guide::ALL.length} " \
     "errors=#{rows.count { |row| row[:error] }}"
