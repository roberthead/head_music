# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Places a voice's marks that take no time, such as its dynamic levels, at
  # their exact positions among the links the voice is written in. A mark
  # where a link attacks is written after that link. A mark inside a link is
  # written with \after on it, which leaves the link whole. A mark after the
  # voice's last link in a bar is left for the spacers that follow the music.
  #
  # Offsets are fractions of a whole note into a bar, as the links' are.
  #
  # At one position, a hairpin's end comes first, then a level or accent, then
  # a hairpin's start, so one hairpin can end where the next begins.
  class TimedMarks
    END_RANK = 0
    LEVEL_RANK = 1
    START_RANK = 2
    HAIRPIN_TOKENS = {"crescendo" => "\\<", "diminuendo" => "\\>"}.freeze

    Mark = Data.define(:bar_number, :offset, :token, :label, :rank) do
      def initialize(bar_number:, offset:, token:, label:, rank: LEVEL_RANK)
        super
      end
    end

    # The voice's levels and hairpins. LilyPond ends a hairpin at a level or
    # accent in its voice, so a hairpin is written in pieces that meet there.
    def self.voice(voice)
      accents = voice.voice_events.select(&:note_dynamic).map(&:position)
      new(level_marks(voice) + hairpin_marks(voice.spans, voice.dynamic_events.map(&:position) + accents))
    end

    # A part's levels and hairpins, the hairpins cut at its own levels.
    def self.part(part)
      new(part.dynamic_events.map { |event| level_mark(event) } + hairpin_marks(part.spans, part.dynamic_events.map(&:position)))
    end

    # The voice's levels that are in force where they fall, since an accent
    # such as fp on the same note overrides its level there.
    def self.level_marks(voice)
      events = voice.dynamic_events.select { |event| voice.dynamic_at(event.position) == event.level }
      events.map { |event| level_mark(event) }
    end

    def self.level_mark(event)
      mark(event.position, "\\#{event.level.name_key}", "dynamic #{event.name_key}")
    end

    def self.hairpin_marks(spans, cuts)
      HeadMusic::Notation::HairpinSegments.split(spans.select(&:hairpin?), cuts).flat_map do |piece|
        [
          mark(piece.to, "\\!", "#{piece.name_key} end", rank: END_RANK),
          mark(piece.from, HAIRPIN_TOKENS.fetch(piece.name_key), "#{piece.name_key} start", rank: START_RANK)
        ]
      end
    end

    def self.mark(position, token, label, rank: LEVEL_RANK)
      Mark.new(position.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(position), token, "#{label} at #{position}", rank)
    end

    # How far into a link an \after reaches: a duration where one note value
    # spans it, and a multiplied whole note otherwise.
    def self.duration(fraction)
      value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      return DurationWriter.token(value) if value && !value.tied_value

      "1*#{fraction.numerator}/#{fraction.denominator}"
    end

    def initialize(marks)
      @marks_by_bar = marks.sort_by { |mark| [mark.offset, mark.rank] }.group_by(&:bar_number)
    end

    # A link's word with the marks inside it before and those where it
    # attacks after, with the link's own marks, such as an accent, among them.
    def around(bar_number, from, to, word, own = "")
      "#{afters(bar_number, from, to)}#{word}#{attacks(bar_number, from, own)}"
    end

    # What follows the link that starts at the offset: ends and levels, the
    # link's own marks, then starts.
    def attacks(bar_number, offset, own = "")
      starts, others = marks_in(bar_number).select { |mark| mark.offset == offset }.partition { |mark| mark.rank == START_RANK }
      "#{others.map(&:token).join}#{own}#{starts.map(&:token).join}"
    end

    # What precedes the link: an \after for each mark inside it.
    def afters(bar_number, from, to)
      marks_in(bar_number).select { |mark| mark.offset > from && mark.offset < to }
        .map { |mark| "\\after #{self.class.duration(mark.offset - from)} #{mark.token} " }.join
    end

    # The marks at or after the offset where the voice's music in the bar ends.
    def trailing(bar_number, offset)
      marks_in(bar_number).select { |mark| mark.offset >= offset }
    end

    private

    def marks_in(bar_number)
      @marks_by_bar.fetch(bar_number, [])
    end
  end
end
