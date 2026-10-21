# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes one voice as a string per bar of the flow, each with its bar lines.
  # Every voice writes every bar, so the voices' lines break at the same bars:
  # a bar the voice is silent in, before it enters or after it ends, is
  # written as rests.
  class VoiceWriter
    attr_reader :voice, :plan

    def initialize(voice, plan)
      @voice = voice
      @plan = plan
    end

    # Raises on what the voice cannot write before any bar is assembled.
    def validate!
      ensure_marks_reachable
      slur_writer
    end

    def bars
      written = written_bars
      plan.bar_numbers.map do |bar_number|
        bar = plan.bar(bar_number)
        BarLineWriter.opening(bar, plan.bar(bar_number - 1), fields(bar_number), lead: lead?) +
          written.fetch(bar_number) { bar_writer.silent_bar(bar_number, length(bar_number)) } +
          BarLineWriter.closing(bar, plan.bar(bar_number + 1), lead: lead?)
      end
    end

    private

    # A mark inside a note or after the music is reached by invisible rests,
    # which need a binary note value to span its offset, and which cannot
    # carry a Q: field.
    def ensure_marks_reachable
      segments_by_bar.each_value do |bar_segments|
        bar_marks = position_marks.bar_marks(bar_segments)
        mark = bar_marks.unreachable
        if mark
          raise RenderError, "cannot place the #{mark.label} at #{mark.position} in ABC output: " \
            "no binary note value reaches it"
        end
        field = bar_marks.inline_field_between_attacks
        raise RenderError, "cannot place the #{field.label} at #{field.position} in ABC output, where no note starts" if field
      end
    end

    # The flow's tempo marks, part labels, and navigation are written once,
    # in the first voice.
    def lead?
      plan.lead?(voice)
    end

    # A part's own dynamics and hairpins are written in its first voice.
    def part_marks?
      voice.equal?(voice.part.voices.first)
    end

    # The key its part reads, which in a transposed plan is the part's own
    # written key.
    def key_signature
      plan.first_measure_key(voice.part).key_signature
    end

    # Each bar the voice sounds in, with its music, spelled in the key in
    # force there. Where the voice ends before the music does, its last bar
    # is filled with rests.
    def written_bars
      last_bar_number = segments_by_bar.keys.last
      ends_early = voice.last_voice_event && voice.last_voice_event.next_position < plan.music_end
      segments_by_bar.to_h do |bar_number, bar_segments|
        fill_to = length(bar_number) if ends_early && bar_number == last_bar_number
        [bar_number, bar_writer.bar(bar_segments, plan.measure_key_at(bar_number, voice.part).key_signature, fill_to: fill_to)]
      end
    end

    # A whole bar, or the final bar as far as the music reaches into it.
    def length(bar_number)
      final = plan.music_end_fraction if bar_number == plan.bar_numbers.last
      final || plan.effective_meter(bar_number).then { |meter| Rational(meter.top_number, meter.bottom_number) }
    end

    # Every voice states each change, so no reader has to carry one voice's
    # field to another. The header's K: already names the first bar's key.
    def fields(bar_number)
      meter = plan.measure_time_changes[bar_number]
      key = plan.measure_key_changes(voice.part)[bar_number] unless bar_number == plan.bar_numbers.first
      "#{"[M:#{Writer.meter_value(meter)}]" if meter}#{"[K:#{key}]" if key}"
    end

    def bar_writer
      @bar_writer ||= BarWriter.new(
        key_signature, Writer::UNIT_NOTE_LENGTH, slur_writer, position_marks, tuplet_writer, plan.fermata_carriers
      )
    end

    # A voice event sounding across a bar line is written as one note per bar,
    # tied, since ABC has no other way to cross the line.
    def segments_by_bar
      plan.segments_by_bar(voice)
    end

    def segments
      segments_by_bar.values.flatten
    end

    def position_marks
      @position_marks ||= PositionMarks.new(voice, lead: lead?, part: part_marks?)
    end

    def slur_writer
      @slur_writer ||= SlurWriter.new(voice)
    end

    def tuplet_writer
      TupletWriter.new(voice, segments)
    end
  end
end
