#!/usr/bin/env ruby
# Dumps the customer-facing strings for every distinct guide item, one JSON row
# per (guideline, config) pair.
#
#   bundle exec ruby bin/guide_item_strings.rb out.json
#
# A violation is previewed rather than assessed: GuideItemAssessment#message is
# nil for an adherent voice, so assessing would report nothing for exactly the
# guidelines a voice happens to satisfy.

require "json"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift File.join(ROOT, "lib")

require "head_music"

items = HeadMusic::Style::Guide::ALL.flat_map(&:guide_items).uniq

rows = items.map do |item|
  {
    guideline: item.guideline.name.split("::").last,
    config: item.config.empty? ? nil : item.config.inspect,
    message: begin
      item.violation_preview
    rescue => error
      "!! #{error.class}: #{error.message}"
    end,
    name: item.name,
    instruction: item.instruction
  }
end.sort_by { |row| [row[:guideline], row[:config].to_s] }

File.write(ARGV.fetch(0), JSON.pretty_generate(rows))
warn "items=#{rows.length} errors=#{rows.count { |row| row[:message].to_s.start_with?("!!") }}"
