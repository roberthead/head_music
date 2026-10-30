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
      @rest_writer = RestWriter.new(@duration_writer)
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
      music + @rest_writer.trailing(bar_marks, fill_to) + @rest_writer.overlay(bar_marks)
    end

    # A bar the voice is silent in, as rests carrying the marks there.
    def silent_bar(bar_number, fill_to)
      @rest_writer.trailing(@position_marks.silent_bar_marks(bar_number), fill_to).lstrip
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
      length = segment.fraction || voice_event.rhythmic_duration.fraction
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
      rhythmic_duration = voice_event.rhythmic_duration
      pieces = @tuplet_writer.pieces(segment)
      return untupled_parts(segment) unless pieces

      pieces.map { |piece| [piece.marker, multiplier_for(piece.links.sum(&:written_fraction), rhythmic_duration)] }
    end

    def untupled_parts(segment)
      rhythmic_duration = segment.voice_event.rhythmic_duration
      split = fermata_split(segment)
      return [["", multiplier_for(segment.fraction, rhythmic_duration)]] unless split

      length = segment.fraction || rhythmic_duration.fraction
      [["", multiplier_for(split, rhythmic_duration)], ["", multiplier_for(length - split, rhythmic_duration), "!fermata!"]]
    end

    def sounding_token(voice_event, multiplier, forced)
      return "z#{multiplier}" if voice_event.rest?
      return "[#{@pitch_writer.chord_tokens(voice_event.pitches, forced: forced).join}]#{multiplier}" if voice_event.chord?

      "#{@pitch_writer.token(voice_event.pitch)}#{multiplier}"
    end

    def multiplier_for(fraction, rhythmic_duration)
      return @duration_writer.multiplier_string(rhythmic_duration) unless fraction

      @duration_writer.multiplier_string_for_fraction(fraction, rhythmic_duration)
    end

    def render_error_class
      RenderError
    end
  end
end
