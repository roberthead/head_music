# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads one data field of a **kern spine: a null token, a note, a rest,
  # or a chord of space-separated notes.
  #
  # Articulations, ornaments, and the sforzando z are read as markings,
  # which a rest drops and a chord gathers from all its notes. Slur and
  # phrase marks are kept as written, on notes and rests alike, and so is a
  # fermata, which a chord holds when any of its notes does.
  #
  # A grace note is q, slashed, or Q or qq, unslashed. Its value is the
  # written one, an eighth when none is given, and it keeps its pitches,
  # articulations, tie, and span marks; its ornaments and sforzando are
  # dropped. A field of grace notes alone is one grace note, a chord when it
  # has several; one beside a note in a chord is dropped.
  # Signifiers the gem does not model (beams, stems, bowings, other
  # ornaments, editorial marks) are dropped. Anything else is
  # rejected rather than guessed at.
  class TokenReader
    # A token's :type is :null, :grace, :rest, or :note (one or more
    # pitches). Its :tie is nil, :start ([), :middle (_), or :end (]).
    # Its markings are catalog keys: sorted articulation and ornament
    # keys, and a note dynamic or nil. Its span marks are the slur and
    # phrase signifiers, such as "(", "}", or the elided "&(". A rest
    # marked yy is invisible. A note or rest marked ; holds a fermata, even
    # one hidden as ;y. A grace note has no fraction, since it takes
    # no time, and may be slashed.
    Token = Data.define(
      :type, :pitches, :rhythmic_duration, :fraction, :tie, :articulations, :ornaments, :note_dynamic, :span_marks, :invisible,
      :slashed, :fermata
    ) do
      def initialize(
        articulations: [], ornaments: [], note_dynamic: nil, span_marks: [], invisible: false, slashed: false, fermata: false,
        **fields
      )
        super
      end

      def attack?
        %i[rest note].include?(type)
      end
    end

    NULL = Token.new(type: :null, pitches: [], rhythmic_duration: nil, fraction: nil, tie: nil)
    TIES = {"[" => :start, "_" => :middle, "]" => :end}.freeze
    GRACE_MARKS = %w[q Q].freeze
    DEFAULT_GRACE_DURATION = HeadMusic::Rudiment::RhythmicDuration.get(:eighth)
    # Beams and partial beams, stems, fermatas once read, the inverted turn
    # and the ornament-ending turn, other ornaments, bowings, breath and arpeggio
    # marks, and editorial and visibility marks.
    IGNORED = %W[L J K k / \\ ; " , : & < > ? x X y $ O R u v].freeze
    SPAN_BRACKETS = "(){}"

    RECIP = /(\d+(?:%\d+)?)(\.*)/
    PITCH = /([a-gA-G])\1*/
    ACCIDENTAL = /\A(?:#+|-+|n)/

    def self.read(field, line_number: nil)
      new(field, line_number).token
    end

    def initialize(field, line_number)
      @field = field
      @line_number = line_number
    end

    def token
      return NULL if @field == "."

      graces, subtokens = @field.split(" ").map { |text| subtoken(text) }.partition { |token| token.type == :grace }
      return ChordToken.of_graces(graces, field: @field, line_number: @line_number) if subtokens.empty?

      ChordToken.of_notes(subtokens, field: @field, line_number: @line_number)
    end

    private

    def subtoken(text)
      span_marks = span_marks(text)
      remaining = text.delete(SPAN_BRACKETS)
      return grace(text, remaining, span_marks) if GRACE_MARKS.any? { |mark| remaining.include?(mark) }

      duration = read_duration(remaining, text)
      pitches = read_pitches(remaining, text)
      rest = !remaining.delete!("r").nil?
      invisible = rest && remaining.include?("yy")
      tie = read_tie(remaining, text)
      markings = MarkCodes.read!(remaining)
      ensure_consumed(remaining, text)
      token = build(text, duration, pitches, rest, tie).with(span_marks: span_marks, invisible: invisible, fermata: fermata?(text))
      rest ? token : token.with(**markings)
    end

    def fermata?(text)
      text.include?(";")
    end

    def grace(text, remaining, span_marks)
      slashed = !remaining.include?("Q") && !remaining.include?("qq")
      remaining.delete!("qQ")
      duration = read_duration(remaining, text)
      pitches = read_pitches(remaining, text)
      raise parse_error(%(Grace note "#{text}" has no pitch), text) if pitches.empty?

      tie = read_tie(remaining, text)
      articulations = MarkCodes.read!(remaining)[:articulations]
      ensure_consumed(remaining, text)
      Token.new(
        type: :grace, pitches: pitches, rhythmic_duration: grace_duration(duration), fraction: nil, tie: tie,
        articulations: articulations, span_marks: span_marks, slashed: slashed
      )
    end

    # A grace note takes no time, so a tuplet or tied value is written as its
    # first value with no ratio.
    def grace_duration(duration)
      return DEFAULT_GRACE_DURATION unless duration

      rhythmic_duration = duration.rhythmic_duration
      return rhythmic_duration if rhythmic_duration.single_value && !rhythmic_duration.tuplet?

      first = rhythmic_duration.values.first
      HeadMusic::Rudiment::RhythmicDuration.new([HeadMusic::Rudiment::RhythmicValue.new(first.unit, dots: first.dots)])
    end

    # Each slur or phrase mark with the & of each level of elision before it,
    # as "&(". Scanned by hand: Ruby 3.3.0's regex engine misses the ")" in
    # "4g])" for /&*[()]/.
    def span_marks(text)
      elision = +""
      text.each_char.with_object([]) do |char, marks|
        if char == "&"
          elision << char
        else
          marks << "#{elision}#{char}" if SPAN_BRACKETS.include?(char)
          elision = +""
        end
      end
    end

    def read_duration(remaining, text)
      match = RECIP.match(remaining)
      return unless match

      remaining.sub!(match[0], "")
      DurationReader.duration(match[1], match[2], line_number: @line_number, snippet: text)
    end

    def read_pitches(remaining, text)
      match = PITCH.match(remaining)
      return [] unless match

      letters = match[0]
      after = remaining[match.end(0)..]
      accidental = after[ACCIDENTAL].to_s
      remaining[match.begin(0), letters.length + accidental.length] = ""
      if remaining.match?(/[a-gA-G]/) || accidental.length > 2
        raise parse_error(%(Unrecognized pitch in "#{text}"), text)
      end

      [PitchReader.pitch(letters, accidental, line_number: @line_number, snippet: text)]
    end

    def read_tie(remaining, text)
      marks = TIES.keys.select { |mark| remaining.include?(mark) }
      remaining.delete!("[_]")
      raise parse_error(%(Conflicting tie marks in "#{text}"), text) if marks.length > 1

      TIES[marks.first]
    end

    def ensure_consumed(remaining, text)
      stray = remaining.chars.reject { |char| IGNORED.include?(char) }
      return if stray.empty?

      raise UnsupportedFeatureError.new(
        %(Unsupported signifier "#{stray.uniq.join}" in token "#{text}"), line_number: @line_number, snippet: text
      )
    end

    def build(text, duration, pitches, rest, tie)
      if pitches.empty? && !rest
        raise parse_error(%(Token "#{text}" has no pitch or rest), text)
      end
      raise parse_error(%(Token "#{text}" has no duration), text) unless duration
      raise parse_error(%(A rest cannot be tied: "#{text}"), text) if rest && tie

      Token.new(
        type: rest ? :rest : :note, pitches: rest ? [] : pitches,
        rhythmic_duration: duration.rhythmic_duration, fraction: duration.fraction, tie: tie
      )
    end

    def parse_error(message, text)
      ParseError.new(message, line_number: @line_number, snippet: text)
    end
  end
end
