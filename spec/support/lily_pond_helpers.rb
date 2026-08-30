# Structural checks every rendered LilyPond document should pass: balanced
# delimiters, one bar check per bar per voice, and only recognizable tokens
# inside the music expressions. A cheap stand-in for a LilyPond parser.
module LilyPondHelpers
  DURATION = /(?:\d+|\\breve|\\longa|\\maxima)\.*/
  PITCH = /[a-g](?:is|es){0,2}(?:'+|,+)?/
  KEY_COMMAND = /\\key [a-g](?:is|es){0,2} \\[a-z]+/
  TIME_COMMAND = /\\time \d+\/\d+/
  CHORD = /<#{PITCH}(?: #{PITCH})*>#{DURATION}/
  SIMPLE_TOKEN = /\A(?:#{PITCH}#{DURATION}~?|r#{DURATION}|R1\*\d+\/\d+)\z/

  def expect_structurally_valid_lilypond(source, bars:, voices:)
    expect(source.count("{")).to eq source.count("}")
    expect(source.scan("<<").length).to eq source.scan(">>").length
    expect(source).to end_with "\n"
    music_lines = bar_check_lines(source)
    expect(music_lines.length).to eq bars * voices
    music_lines.each { |line| expect_valid_music_line(line) }
  end

  def bar_check_lines(source)
    source.lines.map(&:strip).select { |line| line.end_with?(" |") }
  end

  private

  def expect_valid_music_line(line)
    content = line.sub(/ \|\z/, "")
    content = content.gsub(KEY_COMMAND, "").gsub(TIME_COMMAND, "")
    content = content.gsub(/#{CHORD}~?/, "")
    expect(content.split).to all(match(SIMPLE_TOKEN))
  end
end

RSpec.configure { |config| config.include LilyPondHelpers }
