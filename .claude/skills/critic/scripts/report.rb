# Summarizes tmp/rubycritic/report.json for a code-quality pass.
#
#   ruby .claude/skills/critic/scripts/report.rb [--top N] [--target SCORE]
#        [--save FILE] [--compare FILE]
#
# The score is 100 - 6.25 * average file cost, each file's cost capped at 32,
# and a file's cost is its flog complexity (class body excluded) / 25 plus
# the integer mass / 25 of each flay duplicate it takes part in.

require "json"
require "optparse"

options = {top: 15, target: nil, save: nil, compare: nil}
OptionParser.new do |parser|
  parser.on("--top N", Integer) { |value| options[:top] = value }
  parser.on("--target SCORE", Float) { |value| options[:target] = value }
  parser.on("--save FILE") { |value| options[:save] = value }
  parser.on("--compare FILE") { |value| options[:compare] = value }
end.parse!

report_path = "tmp/rubycritic/report.json"
abort "No #{report_path}; run `bundle exec rubycritic` first." unless File.exist?(report_path)

report = JSON.parse(File.read(report_path))
modules = report["analysed_modules"]
total_cost = modules.sum { |file| [file["cost"], 32].min }

puts format("Report written %s", File.mtime(report_path).strftime("%Y-%m-%d %H:%M"))
puts format("Score %.2f  files %d  total cost %.1f  average %.3f",
  report["score"], modules.length, total_cost, total_cost / modules.length)
puts "Ratings  " + modules.map { |file| file["rating"] }.tally.sort.map { |rating, count| "#{rating} #{count}" }.join("  ")

if options[:target]
  allowed = (100 - options[:target]) / 6.25 * modules.length
  puts format("To reach %.2f at this file count: remove %.1f cost units (about %d flog)",
    options[:target], total_cost - allowed, ((total_cost - allowed) * 25).ceil)
end

puts "", "Costliest files (cost = complexity / 25 + duplication)"
modules.max_by(options[:top]) { |file| file["cost"] }.each do |file|
  puts format("  %s %6.2f  flog %6.1f  dup %4d  %s",
    file["rating"], file["cost"], file["complexity"], file["duplication"], file["path"])
end

clusters = modules.flat_map { |file| file["smells"] }
  .select { |smell| smell["type"] == "DuplicateCode" }
  .uniq { |smell| [smell["score"], smell["locations"].map { |location| [location["path"], location["line"]] }.sort] }
  .map do |smell|
    paths = smell["locations"].map { |location| location["path"] }.uniq
    {mass: smell["score"], paths: paths, locations: smell["locations"],
     reclaimable: (smell["score"] / 25) * [paths.length - 1, 1].max}
  end
  .sort_by { |cluster| [-cluster[:reclaimable], -cluster[:mass]] }

puts "", "Duplication clusters (reclaimable = mass / 25 for each file but one)"
clusters.first(options[:top]).each do |cluster|
  puts format("  mass %4d  reclaim %2d  in %d file(s)", cluster[:mass], cluster[:reclaimable], cluster[:paths].length)
  cluster[:locations].each { |location| puts "      #{location["path"]}:#{location["line"]}" }
end

if options[:compare]
  before = JSON.parse(File.read(options[:compare]))
  puts "", format("Since %s: score %.2f -> %.2f, total cost %.1f -> %.1f, files %d -> %d",
    options[:compare], before["score"], report["score"], before["total_cost"], total_cost,
    before["costs"].length, modules.length)
  costs = modules.to_h { |file| [file["path"], file["cost"]] }
  (before["costs"].keys | costs.keys).map { |path| [path, before["costs"][path], costs[path]] }
    .reject { |_, was, now| was && now && (was - now).abs < 0.01 }
    .sort_by { |_, was, now| (now || 0) - (was || 0) }
    .each { |path, was, now| puts format("  %6s -> %6s  %s", was&.round(2) || "new", now&.round(2) || "gone", path) }
end

if options[:save]
  File.write(options[:save], JSON.pretty_generate(
    "score" => report["score"], "total_cost" => total_cost,
    "costs" => modules.to_h { |file| [file["path"], file["cost"]] }
  ) + "\n")
  puts "", "Saved baseline to #{options[:save]}"
end
