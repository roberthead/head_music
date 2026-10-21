# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes a flow's tempo marks as <direction>s, which the first part
  # alone writes: tempo text as <words> and the number as a <metronome>, each
  # its own <direction-type>, then the <offset> and a <sound tempo> in
  # quarter notes per minute. A ramp is its text with <dashes> from its start
  # to its end, where its target is written as a tempo; an "a tempo" is its
  # text, with the tempo it restores to play. An <offset> moves the sound
  # with the words, since a direction's <offset> would otherwise move only
  # how it looks.
  class TempoWriter
    include HeadMusic::Notation::XmlText

    # A flow with no tempo written reads at this one.
    DEFAULT_TEMPO = HeadMusic::Rudiment::Tempo.new("quarter", 120)

    def initialize(flow)
      @flow = flow
    end

    # The opening tempo, unless it is the default, then every later mark.
    def marks
      @marks ||= [*opening_mark, *HeadMusic::Notation::TempoMarks.new(@flow).to_a]
    end

    # A tempo mark at a downbeat with neither text nor a written number is a
    # bare <sound>, since a <direction> needs a <direction-type>.
    def lines(mark, offset, numbers = [])
      types = direction_types(mark)
      return [%(#{INDENT * 3}<sound tempo="#{number(sound_tempo(mark))}"/>)] if types.empty? && offset.zero?

      sound = sound_tempo(mark)
      [
        %(#{INDENT * 3}<direction placement="above">),
        *types.map { |type| "#{INDENT * 4}<direction-type>#{type}</direction-type>" },
        offset.zero? ? nil : %(#{INDENT * 4}<offset sound="yes">#{offset}</offset>),
        *numbers,
        sound && %(#{INDENT * 4}<sound tempo="#{number(sound)}"/>),
        "#{INDENT * 3}</direction>"
      ].compact
    end

    private

    def opening_mark
      tempo = @flow.timeline.opening_tempo
      return [] if tempo == DEFAULT_TEMPO

      position = @flow.position(@flow.earliest_bar_number, HeadMusic::Content::Flow::Timeline::DOWNBEAT, 0)
      [HeadMusic::Notation::TempoMarks::Mark.new(:tempo, position, tempo, tempo.text)]
    end

    def direction_types(mark)
      tempo = mark.tempo
      case mark.kind
      when :ramp_start then [words(mark.text), %(<dashes type="start" number="1"/>)]
      when :ramp_end then [%(<dashes type="stop" number="1"/>), *tempo_types(tempo)]
      when :a_tempo then [words(mark.text || "a tempo")]
      else tempo_types(tempo)
      end
    end

    def tempo_types(tempo)
      return [] unless tempo

      [(words(tempo.text) if tempo.text), (metronome(tempo) if tempo.metronome_mark?)].compact
    end

    def words(text)
      "<words>#{escape(text)}</words>"
    end

    # A beat under a tuplet has no <beat-unit>, so its number is only played.
    def metronome(tempo)
      beat = tempo.beat_value
      type = DurationWriter::TYPES_BY_UNIT_NAME[beat.unit_name]
      return unless type && !beat.tuplet?

      dots = "<beat-unit-dot/>" * beat.dots
      "<metronome><beat-unit>#{type}</beat-unit>#{dots}<per-minute>#{number(tempo.beats_per_minute)}</per-minute></metronome>"
    end

    def sound_tempo(mark)
      tempo = (mark.kind == :a_tempo) ? conductor.tempo_at(mark.position) : mark.tempo
      tempo && tempo.beats_per_minute * tempo.beat_value.fraction * 4
    end

    def conductor
      @conductor ||= @flow.conductor
    end

    def number(value)
      rounded = value.round(4)
      (rounded == rounded.round) ? rounded.round.to_s : rounded.to_f.to_s
    end
  end
end
