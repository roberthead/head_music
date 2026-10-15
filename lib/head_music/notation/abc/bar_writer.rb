# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes the tokens of one bar of a voice after another, carrying the
  # accidental state a re-parse accumulates from bar to bar.
  class BarWriter
    include HeadMusic::Notation::VoiceEventValidation

    def initialize(key_signature, unit_note_length, slur_writer, position_marks, tuplet_writer)
      @pitch_writer = PitchWriter.new(key_signature)
      @duration_writer = DurationWriter.new(unit_note_length)
      @decoration_writer = DecorationWriter.new
      @slur_writer = slur_writer
      @position_marks = position_marks
      @tuplet_writer = tuplet_writer
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
    # and a slur closes after its last part. A tuplet marker comes first, and
    # a slur opens before the decorations, since ".(" would be a dotted slur.
    # A mark at the start of a later part goes on that part.
    def token(segment, bar_marks)
      voice_event = segment.voice_event
      marker, body = token_body(segment)
      body += @slur_writer.closes(voice_event) unless segment.continues
      position = voice_event.position
      unless segment.bar_number == position.bar_number
        return marker + bar_marks.decorations_at(voice_event.flow.position(segment.bar_number, 1, 0)) + body
      end

      marker + @slur_writer.opens(voice_event) + bar_marks.decorations_at(position) + @decoration_writer.prefix(voice_event) + body
    end

    # A hairpin ending on the final barline goes on a spacer there, after
    # invisible rests that fill a short bar.
    def trailing(bar_marks)
      music_end = bar_marks.music_end
      length = bar_marks.length
      closing = bar_marks.closing
      written = []
      if bar_marks.trailing.any?
        written << invisible_rests(music_end, length, bar_marks.trailing)
      elsif closing.any? && music_end < length
        written << "x#{invisible_multiplier(length - music_end)}"
      end
      written << "#{closing.map(&:decoration).join}y" if closing.any?
      written.map { |text| " #{text}" }.join
    end

    def overlay(bar_marks)
      return "" if bar_marks.overlay.empty?

      written_length = bar_marks.trailing.empty? ? bar_marks.music_end : bar_marks.length
      " & " + invisible_rests(0, written_length, bar_marks.overlay)
    end

    # From one offset to another, each mark on the invisible rest starting
    # at its offset.
    def invisible_rests(from, to, marks)
      rests = []
      decorations = ""
      marks.group_by(&:offset).each do |offset, marks_at_offset|
        rests << [offset - from, decorations] if offset > from
        decorations = marks_at_offset.map(&:decoration).join
        from = offset
      end
      rests << [to - from, decorations]
      rests.map { |length, rest_decorations| "#{rest_decorations}x#{invisible_multiplier(length)}" }.join(" ")
    end

    def invisible_multiplier(fraction)
      @duration_writer.multiplier_string_for_fraction(fraction, HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction))
    end

    # The tuplet marker that opens the segment, if any, and its music.
    def token_body(segment)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)

      pieces = @tuplet_writer.pieces(segment)
      return ["", sounding_token(voice_event, multiplier_for(segment), segment.continues)] unless pieces

      last_index = pieces.length - 1
      tokens = pieces.each_with_index.map do |piece, index|
        (index.zero? ? "" : piece.marker) + piece_token(voice_event, piece, index < last_index || segment.continues)
      end
      [pieces.first.marker, tokens.join(voice_event.rest? ? " " : "")]
    end

    # A rest cannot be tied, so a rest's pieces are written as rests.
    def piece_token(voice_event, piece, tied)
      multiplier = @duration_writer.multiplier_string_for_fraction(piece.links.sum(&:written_fraction), voice_event.rhythmic_value)
      sounding_token(voice_event, multiplier, tied)
    end

    def sounding_token(voice_event, multiplier, tied)
      tie = tied ? "-" : ""
      return "z#{multiplier}" if voice_event.rest?
      return chord_token(voice_event, multiplier) + tie if voice_event.chord?

      "#{@pitch_writer.token(voice_event.pitch)}#{multiplier}#{tie}"
    end

    def multiplier_for(segment)
      rhythmic_value = segment.voice_event.rhythmic_value
      return @duration_writer.multiplier_string(rhythmic_value) unless segment.fraction

      @duration_writer.multiplier_string_for_fraction(segment.fraction, rhythmic_value)
    end

    # Pitches are emitted low-to-high so the writer's bar-accidental state
    # cannot diverge from what a re-parse of the brackets accumulates.
    def chord_token(voice_event, multiplier)
      pitch_tokens = voice_event.pitches.sort.map { |pitch| @pitch_writer.token(pitch) }
      "[#{pitch_tokens.join}]#{multiplier}"
    end

    def render_error_class
      RenderError
    end
  end
end
