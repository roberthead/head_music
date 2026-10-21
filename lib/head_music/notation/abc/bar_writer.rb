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
    #
    # A bar the music runs on past, where the voice ends, is filled with rests
    # to +fill_to+, its length as a fraction of a whole note.
    def bar(bar_segments, key_signature, fill_to: nil)
      @pitch_writer.start_new_bar(key_signature)
      bar_marks = @position_marks.bar_marks(bar_segments)
      music = bar_segments.map do |segment|
        token = token(segment, bar_marks)
        (segment.voice_event.beam_break_before == false) ? token : " #{token}"
      end.join.lstrip
      music + trailing(bar_marks, fill_to) + overlay(bar_marks)
    end

    # A bar the voice is silent in, as rests carrying the marks there.
    def silent_bar(bar_number, fill_to)
      trailing(@position_marks.silent_bar_marks(bar_number), fill_to).lstrip
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
      begins = @fermatas.fetch(segment.voice_event, []).any? do |fermata|
        start <= fermata.from && fermata.from < finish && !fermata_split(segment)
      end
      begins ? "!fermata!" : ""
    end

    # How far into a segment written whole a fermata begins, where it begins
    # on a later link of its tied chain, so the segment is written tied there
    # with the fermata on the second part.
    def fermata_split(segment)
      voice_event = segment.voice_event
      length = segment.fraction || voice_event.rhythmic_value.fraction
      boundaries = HeadMusic::Notation::BarSplitter.link_spans(voice_event).map { |_, from, _| from }
      splits = @fermatas.fetch(voice_event, []).filter_map do |fermata|
        HeadMusic::Notation::BarSplitter.offset_in_bar(fermata.from) - segment.offset if fermata.from.bar_number == segment.bar_number
      end
      splits.find { |split| split.positive? && split < length && boundaries.include?(segment.elapsed + split) }
    end

    def lead_in(voice_event)
      [
        @slur_writer.grace_opens(voice_event) + @grace_writer.prefix(voice_event),
        @slur_writer.opens(voice_event), @decoration_writer.prefix(voice_event)
      ]
    end

    # A hairpin ending on the final barline goes on a spacer there, after
    # invisible rests that fill a short bar. A bar filled where the voice ends
    # early is filled with rests instead.
    def trailing(bar_marks, fill_to = nil)
      music_end = bar_marks.music_end
      length = bar_marks.length
      marks = bar_marks.trailing
      closing = bar_marks.closing.map(&:decoration).join
      rests =
        if fill_to && music_end < fill_to
          rests(music_end, fill_to, marks, "z")
        elsif marks.any? || (!closing.empty? && music_end < length)
          rests(music_end, length, marks, "x")
        end
      [rests, ("#{closing}y" unless closing.empty?)].compact.map { |text| " #{text}" }.join
    end

    def overlay(bar_marks)
      marks = bar_marks.overlay
      return "" if marks.empty?

      " & " + rests(0, bar_marks.trailing.empty? ? bar_marks.music_end : bar_marks.length, marks, "x")
    end

    # From one offset to another, each mark on the rest starting at its
    # offset, "x" for an invisible one.
    def rests(from, to, marks, symbol)
      by_offset = marks.group_by(&:offset)
      starts = [from, *by_offset.keys].uniq
      starts.zip([*starts.drop(1), to]).map do |start, finish|
        "#{by_offset.fetch(start, []).map(&:decoration).join}#{symbol}#{rest_multiplier(finish - start)}"
      end.join(" ")
    end

    def rest_multiplier(fraction)
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
      tokens = parts.each_with_index.map do |(marker, multiplier, decoration), index|
        first = index.zero?
        tie = "-" if (index < last_index || segment.continues) && !voice_event.rest?
        "#{marker unless first}#{decoration}#{sounding_token(voice_event, multiplier, first_part && first)}#{tie}"
      end
      [parts.first.first, tokens.join(voice_event.rest? ? " " : "")]
    end

    # Each piece as [its tuplet marker, its multiplier].
    def written_parts(segment)
      voice_event = segment.voice_event
      rhythmic_value = voice_event.rhythmic_value
      pieces = @tuplet_writer.pieces(segment)
      return untupled_parts(segment) unless pieces

      pieces.map { |piece| [piece.marker, multiplier_for(piece.links.sum(&:written_fraction), rhythmic_value)] }
    end

    def untupled_parts(segment)
      rhythmic_value = segment.voice_event.rhythmic_value
      split = fermata_split(segment)
      return [["", multiplier_for(segment.fraction, rhythmic_value)]] unless split

      length = segment.fraction || rhythmic_value.fraction
      [["", multiplier_for(split, rhythmic_value)], ["", multiplier_for(length - split, rhythmic_value), "!fermata!"]]
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
