require "open3"
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
  # A bar's marks and barline carry no duration either.
  BAR_MARK_COMMAND = /\\(?:bar|mark|jump|textEndMark) "(?:[^"\\]|\\.)*"|\\(?:segnoMark|codaMark) \d+|\\fine(?![A-Za-z])/
  # \after places a mark part way into the music that follows, so its
  # duration is an offset, not time.
  AFTER_COMMAND = %r{\\after #{DURATION}(?:\*\d+(?:/\d+)?)? }
  # The marks written after a note or rest carry no duration of their own.
  MARK = /\\(?:ppp|pp|p|mp|mf|f|ff|fff|sf|sfz|rfz|fp|trill|mordent|prall|turn)(?![a-z])|\\[<>!]|-[.!>^-]|(?:\\=\w+)?\\?[()]/
  CHORD = /<#{PITCH}(?: #{PITCH})*>#{DURATION}/
  # <> is a chord of no notes, which carries a mark at a moment without time.
  SIMPLE_TOKEN = /\A(?:#{PITCH}#{DURATION}~?|[rs]#{DURATION}|[Rs]1\*\d+\/\d+|<>)\z/
  # A multiplied whole rest or spacer, which spans what its multiplier says.
  MULTIPLIED = /[Rs]1\*(\d+)\/(\d+)/
  # A tuplet bracket scales the durations inside it by its normal over its
  # actual count, and may open in one bar and close in the next.
  TUPLET_OPEN = %r{\\tuplet (\d+)/(\d+) \{}
  TUPLET_CLOSE = /(?<!\S)\}(?!\S)/
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
    content = strip_commands(content).gsub(TUPLET_OPEN, "").gsub(TUPLET_CLOSE, "")
    content = content.gsub(/#{CHORD}~?/o, "")
    expect(content.split).to all(match(SIMPLE_TOKEN))
  end

  # Walks the document in order, tracking the meter in force (each voice's
  # stream re-declares it, and an inline \time applies to its own bar), and
  # asserts every bar's durations sum to it. A \new Dynamics carries no \time,
  # so its bars are held to the meters the first stream's bars had. A tuplet
  # bracket open at a bar check scales the next bar's durations too.
  def expect_full_bars(source)
    meter = nil
    meters_by_bar = []
    bar_index = 0
    dynamics = false
    tuplets = []
    source.lines.map(&:strip).each do |line|
      if line.start_with?("\\new Dynamics", "\\new Voice")
        dynamics = line.start_with?("\\new Dynamics")
        bar_index = 0
        expect(tuplets).to be_empty
      end
      time_match = line.match(TIME_COMMAND)
      meter = Rational(time_match[1].to_i, time_match[2].to_i) if time_match
      next unless line.end_with?(" |")

      meters_by_bar[bar_index] ||= meter unless dynamics
      expect(bar_duration(line, tuplets)).to eq(dynamics ? meters_by_bar[bar_index] : meter)
      bar_index += 1
    end
  end

  def strip_commands(content)
    content.gsub(AFTER_COMMAND, "").gsub(BAR_MARK_COMMAND, "").gsub(KEY_COMMAND, "").gsub(TIME_COMMAND, "")
      .gsub(CHANGE_STAFF_COMMAND, "").gsub(CLEF_COMMAND, "").gsub(MARK, "")
  end

  # The sounding length of a bar's line. `tuplets` holds the factors of the
  # brackets open at its start, and is left holding those open at its end.
  def bar_duration(line, tuplets = [])
    content = strip_commands(line.sub(/ \|\z/, ""))
    words = []
    content.scan(/#{TUPLET_OPEN}|#{TUPLET_CLOSE}|#{MULTIPLIED}|#{DURATION}/o) { words << Regexp.last_match.to_s }
    words.sum(0r) { |word| scaled_fraction(word, tuplets, line) }
  end

  def scaled_fraction(word, tuplets, line)
    if word.start_with?("\\tuplet")
      actual, normal = word.match(TUPLET_OPEN).captures.map(&:to_i)
      tuplets.push(Rational(normal, actual))
      0r
    elsif word == "}"
      expect(tuplets).not_to be_empty, "a } closes no tuplet in: #{line}"
      tuplets.pop
      0r
    else
      tuplets.inject(1r, :*) * word_fraction(word)
    end
  end

  def word_fraction(word)
    multiplied = word.match(MULTIPLIED)
    multiplied ? Rational(multiplied[1].to_i, multiplied[2].to_i) : duration_fraction(word)
  end

  def duration_fraction(token)
    base = NAMED_DURATION_VALUES[token.delete(".")] || Rational(1, token.to_i)
    base * (2 - Rational(1, 2**token.count(".")))
  end
end

# The real toolchain as an oracle: a rendered document must compile with
# the lilypond binary when one is installed. Callers set `rendered`.
# Pages are typeset but not written, which still fails on bad input and saves
# a quarter of each compile.
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
      system(lilypond, "-dno-print-pages", "--output", dir, source_path, out: File::NULL, err: File::NULL)
    end
  end

  # LilyPond exits zero through most warnings, so this reads its log for them.
  # This is the external tool's log, not the gem's console output.
  def compile_warnings(source)
    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "golden.ly")
      File.write(source_path, source)
      _output, log, _status = Open3.capture3(installed_lilypond, "-l", "WARNING", "-dno-print-pages", "--output", dir, source_path)
      log.lines.grep(/warning|error|programming error/i)
    end
  end

  # Logs a line for each hairpin LilyPond draws, counting one broken across
  # systems once, so a spec can count them. The wider spacing gives a short
  # hairpin between two dynamics room to draw: at the default spacing, a
  # quarter-note hairpin after an sf warns "crescendo too small", which is
  # about the page's width, not the music.
  HAIRPIN_PROBE = <<~'LILYPOND'
    \layout {
      \context {
        \Score
        \override SpacingSpanner.common-shortest-duration = #(ly:make-moment 1/64)
        \override Hairpin.after-line-breaking = #(lambda (grob)
          (let* ((original (ly:grob-original grob))
                 (pieces (if (ly:grob? original) (ly:spanner-broken-into original) '())))
            (if (or (null? pieces) (eq? grob (car pieces)))
                (ly:message "drawn hairpin"))))
      }
    }
  LILYPOND

  # A book set on one page as tall as it needs, so a long one does not warn
  # that LilyPond compressed a page, which is about paper, not the music.
  def on_one_page(source)
    source.sub(/^\\version .*\n/) { |version| version + "\\paper { page-breaking = #ly:one-page-breaking }\n" }
  end

  # The warnings and the number of hairpins drawn, from one compile.
  def compile_hairpins(source)
    probed = source.sub(/^\\version .*\n/) { |version| version + HAIRPIN_PROBE }
    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "golden.ly")
      File.write(source_path, probed)
      _output, log, _status = Open3.capture3(installed_lilypond, "-dno-print-pages", "--output", dir, source_path)
      {warnings: log.lines.grep(/warning|error|programming error/i), hairpins: log.lines.grep(/\Adrawn hairpin/).length}
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

RSpec.shared_examples "a document that compiles without warnings" do
  it "compiles with the lilypond binary without warnings when one is installed" do
    skip "lilypond is not installed" unless installed_lilypond

    expect(compile_warnings(rendered)).to eq []
  end
end

RSpec.configure do |config|
  config.include LilyPondHelpers
  config.include LilyPondToolchain
end
