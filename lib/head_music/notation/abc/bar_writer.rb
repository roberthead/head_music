# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes the tokens of one bar of a voice after another, carrying the
  # accidental state a re-parse accumulates from bar to bar.
  class BarWriter
    include HeadMusic::Notation::VoiceEventValidation

    def initialize(key_signature, unit_note_length, slur_writer, position_marks, tuplet_writer, fermatas = {})
      @pitch_writer = PitchWriter.new(key_signature)
      @duration_writer = DurationWriter.new(unit_note_length)
      @decoration_writer = DecorationWriter.new
      @slur_writer = slur_writer
      @position_marks = position_marks
      @tuplet_writer = tuplet_writer
      @fermatas = fermatas
      @grace_writer = GraceWriter.new(@pitch_writer, @duration_writer, @decoration_writer)
    end

    # The inter-token space is dropped only where the voice event was authored as
    # beamed to its predecessor; a true or nil beam_break_before keeps it, so
    # programmatic flows render with every-token spacing. Every bar token
    # re-lexes unambiguously with no separator, so dropping it is safe.
    def bar(bar_segments)
      @pitch_writer.start_new_bar
      bar_marks = @position_marks.bar_marks(bar_segments)
      music = bar_segments.map do |segment|
        token = token(segment, bar_marks)
        (segment.voice_event.beam_break_before == false) ? token : " #{token}"
      end.join.lstrip
      music + trailing(bar_marks) + overlay(bar_marks)
    end

    private

    # A voice event split across bar lines is marked only where it starts,
    # and a slur closes after its last part. A tuplet marker comes first, then
    # a slur from the grace notes and the grace notes, then a slur from the
    # note, before the decorations, since ".(" would be a dotted slur. A mark
    # at the start of a later part goes on that part, as does a fermata
    # beginning in it. Grace notes are written before the note, so the
    # accidentals they write hold for it.
    def token(segment, bar_marks)
      voice_event = segment.voice_event
      bar_number = segment.bar_number
      position = voice_event.position
      first_part = bar_number == position.bar_number
      graces, opens, decorations = first_part ? lead_in(voice_event) : ["", "", ""]
      marker, body = token_body(segment, first_part)
      start = first_part ? position : voice_event.flow.position(bar_number, 1, 0)
      "#{marker}#{graces}#{opens}#{bar_marks.decorations_at(start)}#{fermata(segment, start)}#{decorations}#{body}" \
        "#{@slur_writer.closes(voice_event) unless segment.continues}"
    end

    def fermata(segment, start)
      finish = segment.continues ? start.start_of_next_bar : segment.voice_event.next_position
      begins = @fermatas.fetch(segment.voice_event, []).any? { |fermata| start <= fermata.from && fermata.from < finish }
      begins ? "!fermata!" : ""
    end

    def lead_in(voice_event)
      [
        @slur_writer.grace_opens(voice_event) + @grace_writer.prefix(voice_event),
        @slur_writer.opens(voice_event), @decoration_writer.prefix(voice_event)
      ]
    end

    # A hairpin ending on the final barline goes on a spacer there, after
    # invisible rests that fill a short bar.
    def trailing(bar_marks)
      music_end = bar_marks.music_end
      length = bar_marks.length
      marks = bar_marks.trailing
      closing = bar_marks.closing.map(&:decoration).join
      rests = invisible_rests(music_end, length, marks) if marks.any? || (!closing.empty? && music_end < length)
      [rests, ("#{closing}y" unless closing.empty?)].compact.map { |text| " #{text}" }.join
    end

    def overlay(bar_marks)
      marks = bar_marks.overlay
      return "" if marks.empty?

      " & " + invisible_rests(0, bar_marks.trailing.empty? ? bar_marks.music_end : bar_marks.length, marks)
    end

    # From one offset to another, each mark on the invisible rest starting
    # at its offset.
    def invisible_rests(from, to, marks)
      by_offset = marks.group_by(&:offset)
      starts = [from, *by_offset.keys].uniq
      starts.zip([*starts.drop(1), to]).map do |start, finish|
        "#{by_offset.fetch(start, []).map(&:decoration).join}x#{invisible_multiplier(finish - start)}"
      end.join(" ")
    end

    def invisible_multiplier(fraction)
      @duration_writer.multiplier_string_for_fraction(fraction, HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction))
    end

    # The tuplet marker that opens the segment, if any, and its music: one
    # token per piece, each but the first after its own marker. A rest
    # cannot be tied, so a rest's pieces are written as rests. Only a
    # chord's first piece forces its clashing members' accidentals.
    def token_body(segment, first_part)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)
      parts = written_parts(segment)
      last_index = parts.length - 1
      tokens = parts.each_with_index.map do |(marker, multiplier), index|
        first = index.zero?
        tie = "-" if (index < last_index || segment.continues) && !voice_event.rest?
        "#{marker unless first}#{sounding_token(voice_event, multiplier, first_part && first)}#{tie}"
      end
      [parts.first.first, tokens.join(voice_event.rest? ? " " : "")]
    end

    # Each piece as [its tuplet marker, its multiplier].
    def written_parts(segment)
      voice_event = segment.voice_event
      rhythmic_value = voice_event.rhythmic_value
      pieces = @tuplet_writer.pieces(segment)
      return [["", multiplier_for(segment.fraction, rhythmic_value)]] unless pieces

      pieces.map { |piece| [piece.marker, multiplier_for(piece.links.sum(&:written_fraction), rhythmic_value)] }
    end

    def sounding_token(voice_event, multiplier, forced)
      return "z#{multiplier}" if voice_event.rest?
      return "[#{@pitch_writer.chord_tokens(voice_event.pitches, forced: forced).join}]#{multiplier}" if voice_event.chord?

      "#{@pitch_writer.token(voice_event.pitch)}#{multiplier}"
    end

    def multiplier_for(fraction, rhythmic_value)
      return @duration_writer.multiplier_string(rhythmic_value) unless fraction

      @duration_writer.multiplier_string_for_fraction(fraction, rhythmic_value)
    end

    def render_error_class
      RenderError
    end
  end
end
