#!/usr/bin/env ruby
# Joins a sequence of guide_grade_corpus.rb captures into one before/after
# document, one section per join.
#
#   bundle exec ruby bin/guide_grade_table.rb out.md \
#     "the strength axis:tmp/c0.json:tmp/c1.json" \
#     "mark softened:tmp/c1.json:tmp/c2.json"
#
# Story-specific by design, and the counterpart of guide_grade_corpus.rb rather
# than a second copy of it: the capture script is written to run UNMODIFIED on
# both sides of a grading change, and this one is a post-processor over the JSON
# it left behind. Editing it cannot influence either column, so it is edited
# after both captures exist.
#
# ATTRIBUTION IS THE CAPTURE BOUNDARY, NOT A JUDGMENT. An earlier version of
# this script guessed the cause from the guide the row belonged to, and
# mislabelled two hundred rows: two changes landing on the same guides cannot be
# told apart after the fact. Each join here spans exactly one change, and its
# label is the cause. A row is relabelled only for the one thing that is visible
# in the data and not in the label -- a voice that changed assessability, which
# is a gate moving rather than a weight, or a row that raised in one capture and
# not the other, which is not a grading change at all.

require "json"

def load_capture(path)
  JSON.parse(File.read(path), symbolize_names: true)
end

def join(before_path, after_path)
  before = load_capture(before_path)
  after = load_capture(after_path)
  indexed = before.to_h { |row| [[row[:corpus], row[:guide]], row] }

  moved = after.filter_map do |row|
    prior = indexed.fetch([row[:corpus], row[:guide]])
    next if unchanged?(prior, row)

    {row: row, prior: prior}
  end
  [after, moved]
end

# An errored row carries fitness: nil, so comparing fitness alone would report
# two identical crashes as a move and then divide nil in the delta column.
def unchanged?(prior, row)
  return prior[:error] == row[:error] if prior[:error] || row[:error]

  prior[:fitness] == row[:fitness]
end

# The error cases come first because an errored row has assessable: nil, which
# the gate comparison would otherwise read as a gate closing.
def why(entry, label)
  prior = entry[:prior]
  row = entry[:row]
  return "crash changed" if prior[:error] && row[:error]
  return "crashes now" if row[:error]
  return "crash fixed" if prior[:error]
  return "gated" if prior[:assessable] != row[:assessable]

  label
end

def title_from(path)
  File.basename(path).sub(/\.grades\.md\z/, "").tr("-", " ")
    .split.map { |word| (word.length > 3) ? word.capitalize : word }.join(" ")
end

def section(label, before_path, after_path)
  after, moved = join(before_path, after_path)
  lines = []
  lines << "## #{label.sub(/\A./, &:upcase)}"
  lines << ""
  lines << "`#{File.basename(before_path)}` → `#{File.basename(after_path)}`. " \
           "#{moved.length} of #{after.length} rows moved, #{after.length - moved.length} unchanged."
  lines << ""

  if moved.empty?
    lines << "No row moved. This change is a provable no-op across the whole corpus."
    lines << ""
    return lines
  end

  tally = moved.group_by { |entry| why(entry, label) }.transform_values(&:length)
  lines << "| why it moved | rows |"
  lines << "| --- | ---: |"
  tally.sort.each { |reason, count| lines << "| #{reason} | #{count} |" }
  lines << ""
  lines << "| corpus | notes | guide | before | after | delta | assessable | why |"
  lines << "| --- | ---: | --- | ---: | ---: | ---: | --- | --- |"
  moved.each do |entry|
    row = entry[:row]
    prior = entry[:prior]
    raised = prior[:error] || row[:error]
    was = prior[:error] ? "raised" : format("%.3f", prior[:fitness])
    now = if row[:error]
      "raised"
    else
      format("%.3f", row[:fitness]) + (row[:assessable] ? "" : "*")
    end
    delta = raised ? "—" : format("%+.3f", row[:fitness] - prior[:fitness])
    assessable = if row[:error]
      "—"
    else
      row[:assessable] ? "yes" : "no"
    end
    lines << "| #{row[:corpus]} | #{row[:notes]} | `#{row[:guide]}` | #{was} | #{now} | " \
             "#{delta} | #{assessable} | #{why(entry, label)} |"
  end
  lines << ""
  lines
end

out_path = ARGV.fetch(0)
joins = ARGV.drop(1).map { |spec| spec.split(":", 3) }
raise ArgumentError, "give at least one label:before:after join" if joins.empty?

first_capture = load_capture(joins.first[1])
last_capture = load_capture(joins.last[2])
guides = first_capture.map { |row| row[:guide] }.uniq.length
entries = first_capture.map { |row| row[:corpus] }.uniq.length

harmony = last_capture.select { |row| row[:guide].end_with?("harmony") }
assessable = harmony.select { |row| row[:assessable] }
synthetic_entries = assessable.map { |row| row[:corpus] }.uniq.grep(/\Aagainst-|\Asolo-/)
synthetic = assessable.count { |row| synthetic_entries.include?(row[:corpus]) }

lines = []
lines << "# #{title_from(out_path)} — grades before and after"
lines << ""
lines << "Generated. Do not edit by hand:"
lines << ""
lines << "```"
joins.each_with_index do |(_label, before_path, after_path), index|
  lines << "bundle exec ruby bin/guide_grade_corpus.rb #{before_path}" if index.zero?
  lines << "bundle exec ruby bin/guide_grade_corpus.rb #{after_path}"
end
lines << "bundle exec ruby bin/guide_grade_table.rb #{out_path} \\"
joins.each_with_index do |(label, before_path, after_path), index|
  suffix = (index == joins.length - 1) ? "" : " \\"
  lines << "  \"#{label}:#{before_path}:#{after_path}\"#{suffix}"
end
lines << "```"
lines << ""
assessable_entries = assessable.map { |row| row[:corpus] }.uniq.length
harmony_guides = harmony.map { |row| row[:guide] }.uniq.length

lines << "The capture script takes no arguments beyond its output path and asks only what " \
         "every tree can answer, so each column is the same measurement made again. " \
         "**#{first_capture.length} rows** per capture — #{entries} corpus entries × #{guides} registry entries. " \
         "An asterisk marks an unassessable voice."
lines << ""
lines << "**Two denominators live in the harmony numbers and must not be conflated.** Of the " \
         "#{harmony.length} harmony rows, only **#{assessable.length} are assessable** — " \
         "#{assessable_entries} entries × #{harmony_guides} harmony guides. Of those, " \
         "**#{assessable.length - synthetic}** come from published fixtures " \
         "(#{assessable_entries - synthetic_entries.length} voices) and **#{synthetic}** from " \
         "#{synthetic_entries.length} synthetic ladder-against-cantus " \
         "#{(synthetic_entries.length == 1) ? "voice" : "voices"}. Every assessable harmony row is " \
         "first-species or ladder material: there are no second, third, fourth, or fifth species " \
         "fixtures anywhere in `spec/`, so this corpus compares each line against itself rather " \
         "than against a line of another species."
lines << ""
lines << "One section per join, and **each join spans exactly one change**, so its label is its " \
         "cause rather than a guess made from the numbers. A row is relabelled only when the " \
         "voice changed assessability, which is a gate moving rather than a weight."
lines << ""

joins.each { |label, before_path, after_path| lines.concat(section(label, before_path, after_path)) }

File.write(out_path, lines.join("\n").rstrip + "\n")
warn joins.map { |label, before_path, after_path| "#{label}=#{join(before_path, after_path).last.length}" }.join(" ")
