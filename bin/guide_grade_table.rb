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

# Two captures need not hold the same guides. A story that registers a guide
# adds rows; one that renames or removes a registry key takes rows away. Both
# are reported and neither is counted as movement -- folding either into
# "N of M rows moved" would read as a grading change to guides that did not
# have one, and an unconditional fetch would simply raise on the first added row.
#
# Removed rows are the dangerous half, because nothing raises: they are absent
# from the after capture, so they never enter the denominator and the section
# would claim full coverage over rows it never looked at. Draw a capture
# boundary across a rename without this and "a provable no-op across the whole
# corpus" prints over hundreds of dropped rows.
def join(before_path, after_path)
  before = load_capture(before_path)
  after = load_capture(after_path)
  indexed = before.to_h { |row| [[row[:corpus], row[:guide]], row] }
  after_keys = after.to_h { |row| [[row[:corpus], row[:guide]], row] }

  joined, added = after.partition { |row| indexed.key?([row[:corpus], row[:guide]]) }
  removed = before.reject { |row| after_keys.key?([row[:corpus], row[:guide]]) }
  moved = joined.filter_map do |row|
    prior = indexed.fetch([row[:corpus], row[:guide]])
    next if unchanged?(prior, row)

    {row: row, prior: prior}
  end
  [joined, moved, added, removed]
end

# Names the registry entries a set of rows belongs to, for the added and removed
# paragraphs.
def entry_summary(rows, verb)
  guides = rows.map { |row| row[:guide] }.uniq
  "#{rows.length} #{(rows.length == 1) ? "row" : "rows"} #{verb}: #{guides.length} registry " \
    "#{(guides.length == 1) ? "entry" : "entries"} " \
    "(#{guides.map { |key| "`#{key}`" }.join(", ")})."
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
  joined, moved, added, removed = join(before_path, after_path)
  lines = []
  lines << "## #{label.sub(/\A./, &:upcase)}"
  lines << ""
  lines << "`#{File.basename(before_path)}` → `#{File.basename(after_path)}`. " \
           "#{moved.length} of #{joined.length} joined rows moved, #{joined.length - moved.length} unchanged."
  unless added.empty?
    lines << ""
    lines << entry_summary(added, "have no before column") + " This change adds them. " \
             "They are new rather than moved, and are excluded from the counts above."
  end
  unless removed.empty?
    lines << ""
    lines << entry_summary(removed, "have no after column") + " This change removes them, " \
             "so nothing here measures them. They are excluded from the counts above, and the " \
             "corpus is not fully covered by this join."
  end
  lines << ""

  if moved.empty?
    # Gated on removed rather than on added. A guide the after capture adds cannot
    # have moved, and the paragraph above has already set those rows aside; the
    # join still covered every row that could have moved. A guide it drops is the
    # case that makes the sentence a lie, because those rows left the denominator
    # without anything raising.
    lines << if removed.empty?
      "No row moved. This change is a provable no-op across the whole corpus."
    else
      "No joined row moved. Every guide both captures hold grades identically; the rows " \
        "named above are outside that claim."
    end
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

# A composite guide beside the two members it is built from. Membership is
# derived from the data rather than a hardcoded list: a key is a composite when
# the capture also holds "<key>_melody" and "<key>_harmony". A story that adds
# an eighth species needs no edit here.
def composite_members(capture)
  keys = capture.map { |row| row[:guide] }.uniq
  keys.to_h { |key| [key, ["#{key}_melody", "#{key}_harmony"]] }
    .select { |_key, pair| pair.all? { |member| keys.include?(member) } }
end

# Only assessable rows carry information. Every solo entry and every cantus
# firmus fixture is a single-voice composition, so its harmony member gates out
# and the composite reads 0.000 by construction.
def composite_rows(capture)
  members = composite_members(capture)
  indexed = capture.to_h { |row| [[row[:corpus], row[:guide]], row] }

  capture.select { |row| members.key?(row[:guide]) && row[:assessable] }.map do |row|
    melody, harmony = members[row[:guide]].map { |member| indexed.fetch([row[:corpus], member]) }
    {row: row, melody: melody, harmony: harmony}
  end
end

def composite_section(capture_path)
  capture = load_capture(capture_path)
  members = composite_members(capture)
  lines = ["## Composites beside their members", ""]
  lines << "Every assessable composite row in `#{File.basename(capture_path)}`, with the two " \
           "grades it was computed from. The last column recomputes the geometric mean from " \
           "the members, so a composite grading by any other rule would show a gap here."
  lines << ""
  lines << "| corpus | notes | composite | grade | melody | harmony | √(m·h) |"
  lines << "| --- | ---: | --- | ---: | ---: | ---: | ---: |"
  composite_rows(capture).each do |entry|
    row = entry[:row]
    melody = entry[:melody][:fitness]
    harmony = entry[:harmony][:fitness]
    lines << "| #{row[:corpus]} | #{row[:notes]} | `#{row[:guide]}` | #{format("%.6f", row[:fitness])} | " \
             "#{format("%.6f", melody)} | #{format("%.6f", harmony)} | " \
             "#{format("%.6f", Math.sqrt(melody * harmony))} |"
  end
  lines << ""
  lines.concat(gated_composites(capture, members))
end

def gated_composites(capture, members)
  gated = capture.select { |row| members.key?(row[:guide]) && !row[:assessable] }
  return [] if gated.empty?

  # Every clause here is derived rather than asserted. An earlier version said
  # these rows were single-voice compositions whose harmony member had no
  # companion and which read 0.000, and all three were false of part of the set:
  # the empty second voice of a cantus-firmus fixture has a companion and fails
  # MinimumNotes instead, and MinimumNotes scores a fraction where
  # SetAgainstAnotherVoice scores zero. Prose about the data is the deliverable
  # here, so it is computed from the data.
  zeroed, fractional = gated.partition { |row| row[:fitness].zero? }
  lines = []
  lines << "The remaining #{gated.length} composite rows are unassessable: at least one member " \
           "failed a gate, so the composite grades on its members' gate factors rather than on " \
           "a rubric it never earned."
  lines << ""
  if fractional.any?
    lines << "#{zeroed.length} of them read 0.000, where a failed gate scored zero. The other " \
             "#{fractional.length} read a fraction, because `MinimumNotes` scores the proportion " \
             "of the minimum a voice reached — #{fraction_examples(fractional)}."
  end
  lines << "" if fractional.any?
  lines << "A gate both members declare is assessed by each of them, so it appears twice in " \
           "the raw capture. Deduplicated per row here rather than in the model, where the flat " \
           "concatenation is what lets a consumer walk members and composite alike. A row " \
           "failing two different gates is counted under each, so the column below sums to more " \
           "than #{gated.length}."
  lines << ""
  lines << "| failed gate | rows failing it |"
  lines << "| --- | ---: |"
  gated.flat_map { |row| row[:failed_gates].uniq }.tally.sort.each do |gate, count|
    lines << "| `#{gate}` | #{count} |"
  end
  lines << ""
  lines
end

# Names a couple of the fractional rows by corpus entry and grade, so the claim
# above can be checked against the table rather than taken on faith.
def fraction_examples(rows)
  rows.group_by { |row| row[:corpus] }.sort.first(2).map { |corpus, group|
    "`#{corpus}` reads #{format("%.6f", group.first[:fitness])}"
  }.join(" and ")
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
         "**#{first_capture.length} rows** in the first capture — #{entries} corpus entries × " \
         "#{guides} registry entries — and **#{last_capture.length}** in the last, #{entries} × " \
         "#{last_capture.map { |row| row[:guide] }.uniq.length}. An asterisk marks an unassessable voice."
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
lines.concat(composite_section(joins.last[2])) if composite_rows(last_capture).any?

File.write(out_path, lines.join("\n").rstrip + "\n")
warn(joins.map { |label, before_path, after_path|
  _joined, moved, added, removed = join(before_path, after_path)
  "#{label}: moved=#{moved.length} added=#{added.length} removed=#{removed.length}"
}.join(" "))
