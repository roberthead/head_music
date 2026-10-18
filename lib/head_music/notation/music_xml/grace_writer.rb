require_relative "note_lines"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the grace notes before a note event as <note> elements that
  # take no time: a <grace> in place of a <duration>, and no beams. A grace
  # chord leads with its lowest pitch, as a chord does. A tied grace note is
  # tied to each pitch of whatever follows it that it shares, the next grace
  # note or the main note, and a slur from the grace notes starts on the
  # first of them.
  class GraceWriter
    include NoteLines

    def initialize(plan)
      @plan = plan
    end

    def lines(voice_event, voice_number: nil, staff_number: nil)
      graces = voice_event.grace_notes
      graces.each_with_index.flat_map do |grace, index|
        ensure_pitched(grace, voice_event)
        follower = graces[index + 1]&.pitches || voice_event.pitches
        tied_in = index.zero? ? [] : graces[index - 1].tied_pitches
        grace.pitches.sort.each_with_index.flat_map do |pitch, pitch_index|
          ties = {stop: tied_in.include?(pitch), start: grace.tied? && follower.include?(pitch)}
          lead = pitch_index.zero?
          note_lines(grace, pitch, ties,
            chord: !lead, slurs: (lead && index.zero?) ? slur_starts(voice_event) : [],
            voice_number: voice_number, staff_number: staff_number)
        end
      end
    end

    # Whether the last grace note before the event ties into this pitch of it.
    def self.tied_into?(voice_event, pitch)
      !!voice_event.grace_notes.last&.tied_pitches&.include?(pitch)
    end

    private

    attr_reader :plan

    def ensure_pitched(grace, voice_event)
      return if grace.sounds.all?(&:pitched?)

      raise RenderError, "cannot render the unpitched #{grace} before the note at #{voice_event.position}: " \
        "percussion rendering is not yet supported"
    end

    def slur_starts(voice_event)
      plan.slur_numbers(voice_event.voice.part).grace_starts_at(voice_event)
    end

    def note_lines(grace, pitch, ties, chord:, slurs:, voice_number:, staff_number:)
      rhythmic_value = grace.rhythmic_value
      [
        "#{INDENT * 3}<note>",
        grace.slashed? ? %(#{INDENT * 4}<grace slash="yes"/>) : "#{INDENT * 4}<grace/>",
        *(chord ? ["#{INDENT * 4}<chord/>"] : []),
        *PitchWriter.lines(pitch),
        *tie_lines("tie", 4, ties),
        number_line("voice", voice_number),
        "#{INDENT * 4}<type>#{type_for(rhythmic_value)}</type>",
        *Array.new(rhythmic_value.dots) { "#{INDENT * 4}<dot/>" },
        number_line("staff", staff_number),
        *notation_lines(grace, ties, chord: chord, slurs: slurs),
        "#{INDENT * 3}</note>"
      ].compact
    end

    def notation_lines(grace, ties, chord:, slurs:)
      notations_lines([
        *tie_lines("tied", 5, ties),
        *slurs.map { |number| slur_line("start", number) },
        *(chord ? [] : marking_group_lines("articulations", grace.articulations, MarkingElements.method(:articulation_element)))
      ])
    end

    def type_for(rhythmic_value)
      DurationWriter::TYPES_BY_UNIT_NAME.fetch(rhythmic_value.unit_name) do
        raise RenderError, "no MusicXML note type is known for #{rhythmic_value.unit_name}"
      end
    end
  end
end
