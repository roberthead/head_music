# Structural checks every rendered LilyPond document should pass: balanced
# delimiters, one bar check per bar per voice, only recognizable tokens
# inside the music expressions, and every bar's durations summing to the
# meter in force — the invariant each trailing bar check asserts at
# compile time. A cheap stand-in for a LilyPond parser.
module LilyPondHelpers
  DURATION = /(?:\d+|\\breve|\\longa|\\maxima)\.*/
  PITCH = /[a-g](?:is|es){0,2}(?:'+|,+)?/
  KEY_COMMAND = /\\key [a-g](?:is|es){0,2} \\[a-z]+/
  TIME_COMMAND = /\\time (\d+)\/(\d+)/
  CHORD = /<#{PITCH}(?: #{PITCH})*>#{DURATION}/
  SIMPLE_TOKEN = /\A(?:#{PITCH}#{DURATION}~?|r#{DURATION}|R1\*\d+\/\d+)\z/
  WHOLE_BAR_REST = /R1\*(\d+)\/(\d+)/
  NAMED_DURATION_VALUES = {"\\breve" => 2r, "\\longa" => 4r, "\\maxima" => 8r}.freeze

  def expect_structurally_valid_lilypond(source, bars:, voices:)
    expect(source.count("{")).to eq source.count("}")
    expect(source.scan("<<").length).to eq source.scan(">>").length
    expect(source).to end_with "\n"
    music_lines = bar_check_lines(source)
    expect(music_lines.length).to eq bars * voices
    music_lines.each { |line| expect_valid_music_line(line) }
    expect_full_bars(source)
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

  # Walks the document in order, tracking the meter in force (each voice's
  # stream re-declares it, and an inline \time applies to its own bar), and
  # asserts every bar's durations sum to it.
  def expect_full_bars(source)
    meter = nil
    source.lines.map(&:strip).each do |line|
      time_match = line.match(TIME_COMMAND)
      meter = Rational(time_match[1].to_i, time_match[2].to_i) if time_match
      next unless line.end_with?(" |")

      expect(bar_duration(line)).to eq meter
    end
  end

  def bar_duration(line)
    content = line.sub(/ \|\z/, "").gsub(KEY_COMMAND, "").gsub(TIME_COMMAND, "")
    whole_bar_rests = content.scan(WHOLE_BAR_REST)
    content = content.gsub(WHOLE_BAR_REST, "")
    rest_sum = whole_bar_rests.sum { |top, bottom| Rational(top.to_i, bottom.to_i) }
    rest_sum + content.scan(DURATION).sum { |token| duration_fraction(token) }
  end

  def duration_fraction(token)
    base = NAMED_DURATION_VALUES[token.delete(".")] || Rational(1, token.to_i)
    base * (2 - Rational(1, 2**token.count(".")))
  end
end

RSpec.configure { |config| config.include LilyPondHelpers }
