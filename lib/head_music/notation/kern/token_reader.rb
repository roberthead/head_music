# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads one data field of a **kern spine: a null token, a note, a rest,
  # or a chord of space-separated notes.
  #
  # Articulations, ornaments, and the sforzando z are read as markings,
  # which a rest drops and a chord gathers from all its notes. Slur and
  # phrase marks are kept as written, on notes and rests alike, and a grace
  # note, which is otherwise dropped, keeps its own for the note after it.
  # Signifiers the gem does not model (beams, stems, fermatas, bowings,
  # other ornaments, editorial marks) are dropped. Anything else is
  # rejected rather than guessed at.
  class TokenReader
    # A token's :type is :null, :grace, :rest, or :note (one or more
    # pitches). Its :tie is nil, :start ([), :middle (_), or :end (]).
    # Its markings are catalog keys: sorted articulation and ornament
    # keys, and a note dynamic or nil. Its span marks are the slur and
    # phrase signifiers, such as "(", "}", or the elided "&(".
    Token = Data.define(:type, :pitches, :rhythmic_value, :fraction, :tie, :articulations, :ornaments, :note_dynamic, :span_marks) do
      def initialize(articulations: [], ornaments: [], note_dynamic: nil, span_marks: [], **fields)
        super
      end

      def attack?
        %i[rest note].include?(type)
      end
    end

    NULL = Token.new(type: :null, pitches: [], rhythmic_value: nil, fraction: nil, tie: nil)
    GRACE = Token.new(type: :grace, pitches: [], rhythmic_value: nil, fraction: nil, tie: nil)
    TIES = {"[" => :start, "_" => :middle, "]" => :end}.freeze
    GRACE_MARKS = %w[q Q].freeze
    # Beams and partial beams, stems, fermatas, the inverted turn and the
    # ornament-ending turn, other ornaments, bowings, breath and arpeggio
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
      return GRACE.with(span_marks: chord_span_marks(graces)) if subtokens.empty?

      combine(subtokens)
    end

    private

    def combine(subtokens)
      return subtokens.first if subtokens.length == 1

      if subtokens.any? { |token| token.type == :rest }
        raise unsupported("A chord cannot hold a rest")
      end
      if subtokens.map(&:fraction).uniq.length > 1
        raise unsupported("Chord notes with different durations are not supported")
      end
      raise unsupported("A chord tied only in part is not supported") if subtokens.map(&:tie).uniq.length > 1

      subtokens.first.with(
        pitches: subtokens.flat_map(&:pitches),
        articulations: subtokens.flat_map(&:articulations).uniq.sort,
        ornaments: subtokens.flat_map(&:ornaments).uniq.sort,
        note_dynamic: subtokens.filter_map(&:note_dynamic).first,
        span_marks: chord_span_marks(subtokens)
      )
    end

    # A chord's notes may each repeat its slur, so a mark counts as often as
    # any one note has it.
    def chord_span_marks(subtokens)
      tallies = subtokens.map { |token| token.span_marks.tally }
      tallies.flat_map(&:keys).uniq.flat_map { |mark| [mark] * tallies.map { |tally| tally.fetch(mark, 0) }.max }
    end

    def subtoken(text)
      span_marks = span_marks(text)
      return GRACE.with(span_marks: span_marks) if GRACE_MARKS.any? { |mark| text.include?(mark) }

      remaining = text.delete(SPAN_BRACKETS)
      duration = read_duration(remaining, text)
      pitches = read_pitches(remaining, text)
      rest = !remaining.delete!("r").nil?
      tie = read_tie(remaining, text)
      markings = MarkCodes.read!(remaining)
      ensure_consumed(remaining, text)
      token = build(text, duration, pitches, rest, tie).with(span_marks: span_marks)
      rest ? token : token.with(**markings)
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
        raise ParseError.new(%(Unrecognized pitch in "#{text}"), line_number: @line_number, snippet: text)
      end

      [PitchReader.pitch(letters, accidental, line_number: @line_number, snippet: text)]
    end

    def read_tie(remaining, text)
      marks = TIES.keys.select { |mark| remaining.include?(mark) }
      remaining.delete!("[_]")
      raise ParseError.new(%(Conflicting tie marks in "#{text}"), line_number: @line_number, snippet: text) if marks.length > 1

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
        raise ParseError.new(%(Token "#{text}" has no pitch or rest), line_number: @line_number, snippet: text)
      end
      raise ParseError.new(%(Token "#{text}" has no duration), line_number: @line_number, snippet: text) unless duration
      raise ParseError.new(%(A rest cannot be tied: "#{text}"), line_number: @line_number, snippet: text) if rest && tie

      Token.new(
        type: rest ? :rest : :note, pitches: rest ? [] : pitches,
        rhythmic_value: duration.rhythmic_value, fraction: duration.fraction, tie: tie
      )
    end

    def unsupported(message)
      UnsupportedFeatureError.new(%(#{message}: "#{@field}"), line_number: @line_number, snippet: @field)
    end
  end
end
