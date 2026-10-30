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
  #
  # The lead voice also carries the flow's tempo marks: a \tempo is music
  # rather than a mark, so it is written before the link that attacks where
  # it falls, and a ramp's or "a tempo"'s words are written as a level is.
  class TimedMarks
    BEFORE_RANK = -1
    END_RANK = 0
    LEVEL_RANK = 1
    START_RANK = 2
    HAIRPIN_TOKENS = {"crescendo" => "\\<", "diminuendo" => "\\>"}.freeze

    # A mark where one of its voices' events starts is at that event's exact
    # onset, which a rounded tuplet position is not.
    Mark = Data.define(:bar_number, :offset, :token, :label, :rank, :onset) do
      def initialize(bar_number:, offset:, token:, label:, rank: LEVEL_RANK, onset: false)
        super
      end

      def before?
        rank == BEFORE_RANK
      end
    end

    TEMPO_LABELS = {tempo: "tempo change", ramp_start: "tempo ramp start", ramp_end: "tempo ramp end", a_tempo: %("a tempo")}.freeze

    # The voice's levels and hairpins. LilyPond ends a hairpin at a level or
    # accent in its voice, so a hairpin is written in pieces that meet there.
    def self.voice(voice, lead: false)
      accents = voice.voice_events.select(&:note_dynamic).map(&:position)
      tempo_marks = lead ? tempo_marks(voice) : []
      new(level_marks(voice) + hairpin_marks(voice.spans, voice.dynamic_events.map(&:position) + accents, [voice]) + tempo_marks)
    end

    # Those on the final barline are written after the music instead.
    def self.tempo_marks(voice)
      final_barline = voice.flow.final_barline_position
      HeadMusic::Notation::TempoMarks.new(voice.flow).filter_map do |tempo_mark|
        next if tempo_mark.position == final_barline

        token, rank = tempo_token(tempo_mark)
        token && mark(tempo_mark.position, token, TEMPO_LABELS.fetch(tempo_mark.kind), rank: rank, voices: [voice])
      end
    end

    # A ramp's end writes its target, where it has one.
    def self.tempo_token(tempo_mark)
      if %i[tempo ramp_end].include?(tempo_mark.kind)
        [TempoWriter.token(tempo_mark.tempo), BEFORE_RANK] if tempo_mark.tempo
      else
        [TempoWriter.text_mark(tempo_mark.text), LEVEL_RANK]
      end
    end

    # A part's levels and hairpins, the hairpins cut at its own levels.
    def self.part(part)
      levels = part.dynamic_events.map { |event| level_mark(event, part.voices) }
      new(levels + hairpin_marks(part.spans, part.dynamic_events.map(&:position), part.voices))
    end

    # The voice's levels that are in force where they fall, since an accent
    # such as fp on the same note overrides its level there.
    def self.level_marks(voice)
      events = voice.dynamic_events.select { |event| voice.dynamic_at(event.position) == event.level }
      events.map { |event| level_mark(event, [voice]) }
    end

    def self.level_mark(event, voices)
      mark(event.position, "\\#{event.level.name_key}", "dynamic #{event.name_key}", voices: voices)
    end

    def self.hairpin_marks(spans, cuts, voices)
      HeadMusic::Notation::HairpinSegments.split(spans.select(&:hairpin?), cuts).flat_map do |piece|
        [
          mark(piece.to, "\\!", "#{piece.name_key} end", rank: END_RANK, voices: voices),
          mark(piece.from, HAIRPIN_TOKENS.fetch(piece.name_key), "#{piece.name_key} start", rank: START_RANK, voices: voices)
        ]
      end
    end

    def self.mark(position, token, label, rank: LEVEL_RANK, voices: [])
      voice_event = voices.lazy.filter_map { |voice| voice.voice_event_at(position) }.first
      bar_number, offset = voice_event ? exact_onset(voice_event) : [position.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(position)]
      Mark.new(bar_number, offset, token, "#{label} at #{position}", rank, !voice_event.nil?)
    end

    # The bar and offset where the voice event's first piece starts.
    def self.exact_onset(voice_event)
      segment = HeadMusic::Notation::BarSplitter.segments_of(voice_event).first
      [segment.bar_number, segment.offset]
    end

    # How far into a link an \after reaches: a duration where one note value
    # spans it, and a multiplied whole note otherwise.
    def self.duration(fraction)
      value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      return DurationWriter.token(value) if value

      "1*#{fraction.numerator}/#{fraction.denominator}"
    end

    def initialize(marks)
      @marks_by_bar = marks.each_with_index.sort_by { |mark, index| [mark.offset, mark.rank, index] }.map(&:first).group_by(&:bar_number)
    end

    # A link's word with the marks inside it before and those where it
    # attacks after, with the link's own marks, such as an accent, among them.
    # The factor is the link's tuplet ratio, inside whose bracket an \after
    # reaches in written time.
    def around(bar_number, from, to, word, own = "", factor: 1)
      "#{befores(bar_number, from)}#{afters(bar_number, from, to, factor: factor)}#{word}#{attacks(bar_number, from, own)}"
    end

    # The commands written before the link that starts at the offset.
    def befores(bar_number, offset)
      marks_in(bar_number).select { |mark| mark.before? && mark.offset == offset }.map { |mark| "#{mark.token} " }.join
    end

    # What follows the link that starts at the offset: ends and levels, the
    # link's own marks, then starts.
    def attacks(bar_number, offset, own = "")
      starts, others = marks_in(bar_number).select { |mark| !mark.before? && mark.offset == offset }.partition { |mark| mark.rank == START_RANK }
      "#{others.map(&:token).join}#{own}#{starts.map(&:token).join}"
    end

    # What precedes the link: an \after for each mark inside it.
    def afters(bar_number, from, to, factor: 1)
      inside = marks_in(bar_number).select { |mark| mark.offset > from && mark.offset < to }
      command = inside.find(&:before?)
      raise RenderError, "cannot place the #{command.label} in LilyPond output, where no note of the first voice starts" if command

      inside
        .map { |mark| "\\after #{self.class.duration((mark.offset - from) / factor)} #{mark.token} " }.join
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
