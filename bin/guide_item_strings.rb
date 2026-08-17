#!/usr/bin/env ruby
# Dumps the customer-facing strings for every distinct guide item, one JSON row
# per (guideline, config) pair.
#
#   bundle exec ruby bin/guide_item_strings.rb out.json
#
# Written to run UNMODIFIED on both sides of the i18n move. Before it, a
# guideline's message comes from the analyzer; after, from a rendered template,
# and the item also answers #instruction. Both shapes are asked for here, so the
# same script produces the before and after columns.
#
# A message is previewed rather than assessed: after the move
# GuideItemAssessment#message is nil for an adherent voice, so assessing would
# report nothing for exactly the guidelines a voice happens to satisfy.

require "json"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift File.join(ROOT, "lib")

require "head_music"

def probe_voice
  composition = HeadMusic::Content::Composition.new(name: "probe", key_signature: "D dorian")
  voice = composition.add_voice(role: :counterpoint)
  %w[D4 F4 E4 D4].each_with_index { |pitch, bar| voice.place("#{bar + 1}:1", :whole, pitch) }
  voice
end

def message_for(item, voice)
  return item.violation_preview if item.respond_to?(:violation_preview)

  item.guideline.send(:new, voice, **item.config).message
end

def string_for(item, method)
  return nil unless item.respond_to?(method)

  item.public_send(method)
end

voice = probe_voice
items = HeadMusic::Style::Guide::ALL.flat_map(&:guide_items).uniq

rows = items.map do |item|
  {
    guideline: item.guideline.name.split("::").last,
    config: item.config.empty? ? nil : item.config.inspect,
    message: begin
      message_for(item, voice)
    rescue => error
      "!! #{error.class}: #{error.message}"
    end,
    name: string_for(item, :name),
    instruction: string_for(item, :instruction)
  }
end.sort_by { |row| [row[:guideline], row[:config].to_s] }

File.write(ARGV.fetch(0), JSON.pretty_generate(rows))
warn "items=#{rows.length} errors=#{rows.count { |row| row[:message].to_s.start_with?("!!") }}"
