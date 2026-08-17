#!/usr/bin/env ruby
# Joins two guide_grade_corpus.rb captures into the before/after table.
#
#   bundle exec ruby bin/guide_grade_table.rb before.json after.json out.md
#
# Every row that moved is attributed to the change responsible. The attribution
# is by guide, because the four changes in this story landed on different
# guides, and "the fitness moved and the voice is still assessable" is not on
# its own enough to tell demotion from a changed threshold -- reading it that
# way mislabelled two hundred rows in an earlier draft of this table.

require "json"

# Read off the declarations, not inferred from the numbers.
#
# The species guides are the ones that route their declarations through
# SpeciesMelody.species_items, so their inherited craft moved to secondary.
DEMOTED = %w[
  first_species_melody second_species_melody third_species_melody
  third_species_triple_meter_melody fourth_species_melody
  combined_first_second_third_species_melody fifth_species_melody
].freeze

# These kept flat rubrics and split their note minimum into a gate plus a
# prescription. The contour guides inherit DiatonicMelody's, so they move with
# it.
SPLIT = (%w[fux_cantus_firmus salzer_schachter_cantus_firmus diatonic_melody] +
  %w[arch ascending descending static valley wave].map { |c| "#{c}_contour_melody" }).freeze

def why(before, after)
  return "crash fixed" if before[:error]
  return "gated" unless after[:assessable]
  return "demoted" if DEMOTED.include?(after[:guide])
  return "threshold split" if SPLIT.include?(after[:guide])

  "gate added"
end

before_path, after_path, out_path = ARGV
before = JSON.parse(File.read(before_path), symbolize_names: true)
after = JSON.parse(File.read(after_path), symbolize_names: true)
indexed = before.to_h { |row| [[row[:corpus], row[:guide]], row] }

moved = after.filter_map do |row|
  prior = indexed.fetch([row[:corpus], row[:guide]])
  next if !prior[:error] && prior[:fitness] == row[:fitness]

  {row: row, prior: prior, why: why(prior, row)}
end

tally = moved.group_by { |entry| entry[:why] }.transform_values(&:length)

lines = []
lines << "# Re-tier the Guides — grades before and after"
lines << ""
lines << "Generated. Do not edit by hand:"
lines << ""
lines << "```"
lines << "bundle exec ruby bin/guide_grade_corpus.rb before.json   # at the merge-base"
lines << "bundle exec ruby bin/guide_grade_corpus.rb after.json    # here"
lines << "bundle exec ruby bin/guide_grade_table.rb before.json after.json \\"
lines << "  user-stories/current/re-tier-the-guides.grades.md"
lines << "```"
lines << ""
lines << "The capture script takes no arguments beyond its output path and asks only "
lines << "what both trees can answer, so the two columns are the same measurement made "
lines << "twice. **#{after.length} rows** — #{after.length / [before.map { |r| r[:guide] }.uniq.length, 1].max} corpus entries × " \
         "#{before.map { |r| r[:guide] }.uniq.length} registry entries. #{moved.length} moved, " \
         "#{after.length - moved.length} unchanged. An asterisk marks an unassessable voice."
lines << ""
lines << "| why it moved | rows |"
lines << "| --- | ---: |"
tally.sort.each { |reason, count| lines << "| #{reason} | #{count} |" }
lines << ""
lines << "- **crash fixed** — the harmony guides raised for a voice with no companion."
lines << "- **gated** — a precondition now stops the assessment instead of scaling it."
lines << "- **gate added** — a guide gained a precondition it did not have; the voice"
lines << "  clears it, so the grade moves only by the gate's own fitness."
lines << "- **threshold split** — a note minimum became a low gate plus a rubric"
lines << "  prescription. These guides keep flat rubrics; nothing was demoted."
lines << "- **demoted** — the species guides weigh what they teach above what they"
lines << "  inherit."
lines << ""
lines << "## Every row that moved"
lines << ""
lines << "| corpus | notes | guide | before | after | delta | assessable | why |"
lines << "| --- | ---: | --- | ---: | ---: | ---: | --- | --- |"
moved.each do |entry|
  row = entry[:row]
  prior = entry[:prior]
  was = prior[:error] ? "raised" : format("%.3f", prior[:fitness])
  now = format("%.3f", row[:fitness]) + (row[:assessable] ? "" : "*")
  delta = prior[:error] ? "—" : format("%+.3f", row[:fitness] - prior[:fitness])
  lines << "| #{row[:corpus]} | #{row[:notes]} | `#{row[:guide]}` | #{was} | #{now} | " \
           "#{delta} | #{row[:assessable] ? "yes" : "no"} | #{entry[:why]} |"
end

File.write(out_path, lines.join("\n") + "\n")
warn "moved=#{moved.length} #{tally.sort.map { |k, v| "#{k}=#{v}" }.join(" ")}"
