require "tmpdir"

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
  # A voice moves between the staves of its own part with \change Staff, which
  # carries no duration and so is stripped like the other commands.
  CHANGE_STAFF_COMMAND = /\\change Staff = "[^"]+"/
  CLEF_COMMAND = /\\clef [a-z]+/
  CHORD = /<#{PITCH}(?: #{PITCH})*>#{DURATION}/
  SIMPLE_TOKEN = /\A(?:#{PITCH}#{DURATION}~?|r#{DURATION}|R1\*\d+\/\d+)\z/
  WHOLE_BAR_REST = /R1\*(\d+)\/(\d+)/
  NAMED_DURATION_VALUES = {"\\breve" => 2r, "\\longa" => 4r, "\\maxima" => 8r}.freeze

  # `streams:` is how many bar-per-line music streams the document holds. It
  # is the voice count for the one-staff-per-voice documents that make up most
  # of the suite, but a part whose staves outnumber its voices carries a
  # rest-filled stream for each staff nobody is written on, so the two part
  # ways as soon as a piano appears.
  def expect_structurally_valid_lilypond(source, bars:, voices:, streams: voices)
    expect(source.count("{")).to eq source.count("}")
    expect(source.scan("<<").length).to eq source.scan(">>").length
    expect(source).to end_with "\n"
    music_lines = bar_check_lines(source)
    expect(music_lines.length).to eq bars * streams
    music_lines.each { |line| expect_valid_music_line(line) }
    expect_full_bars(source)
  end

  def bar_check_lines(source)
    source.lines.map(&:strip).select { |line| line.end_with?(" |") }
  end

  private

  def expect_valid_music_line(line)
    content = line.sub(/ \|\z/, "")
    content = strip_commands(content)
    content = content.gsub(/#{CHORD}~?/o, "")
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

  def strip_commands(content)
    content.gsub(KEY_COMMAND, "").gsub(TIME_COMMAND, "")
      .gsub(CHANGE_STAFF_COMMAND, "").gsub(CLEF_COMMAND, "")
  end

  def bar_duration(line)
    content = strip_commands(line.sub(/ \|\z/, ""))
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

# The real toolchain as an oracle: a rendered document must compile with
# the lilypond binary when one is installed. Callers set `rendered`.
module LilyPondToolchain
  def installed_lilypond
    ENV["PATH"].split(File::PATH_SEPARATOR)
      .map { |dir| File.join(dir, "lilypond") }
      .find { |path| File.executable?(path) }
  end

  def compile_quietly(lilypond, source)
    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "golden.ly")
      File.write(source_path, source)
      system(lilypond, "--output", dir, source_path, out: File::NULL, err: File::NULL)
    end
  end
end

RSpec.shared_examples "a compilable document" do
  it "compiles with the lilypond binary when one is installed" do
    lilypond = installed_lilypond
    skip "lilypond is not installed" unless lilypond

    expect(compile_quietly(lilypond, rendered)).to be true
  end
end

RSpec.configure do |config|
  config.include LilyPondHelpers
  config.include LilyPondToolchain
end
