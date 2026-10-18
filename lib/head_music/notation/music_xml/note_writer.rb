# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the <note> elements a voice event occupies.
  #
  # A voice event becomes one <note> per tied component per sounding pitch in
  # each bar it sounds in: the components come from the render plan's duration
  # split, and a chord renders as a lead note followed by its <chord/> members.
  class NoteWriter
    include NoteLines
    include HeadMusic::Notation::VoiceEventValidation

    def initialize(plan)
      @plan = plan
      @lyric_writer = LyricWriter.new
      @grace_writer = GraceWriter.new(plan)
    end

    # @param voice_number [Integer, nil] the <voice> a part's notes belong to,
    #   omitted for a part holding one voice
    # @param staff_number [Integer, nil] the <staff> the note is written on,
    #   omitted for a part on one staff
    def lines(segment, voice_number: nil, staff_number: nil)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)

      numbers = {voice_number: voice_number, staff_number: staff_number}
      graces = segment.elapsed.zero? ? grace_writer.lines(voice_event, **numbers) : []
      graces + components_by_segment[segment].each_with_index.flat_map do |component, component_index|
        beams = beam_annotations[[segment, component_index]] || []
        component_lines(voice_event, component, beams, tuplet_marks.at(segment, component_index), numbers)
      end
    end

    # The whole-measure rest that stands in for a bar the voice places nothing
    # in. It belongs to its voice and staff as much as a note does, or a reader
    # stacks it onto voice 1 of staff 1.
    def whole_measure_rest_lines(bar_number, voice_number: nil, staff_number: nil)
      [
        "#{INDENT * 3}<note>",
        %(#{INDENT * 4}<rest measure="yes"/>),
        "#{INDENT * 4}<duration>#{plan.whole_measure_duration(bar_number)}</duration>",
        number_line("voice", voice_number),
        number_line("staff", staff_number),
        "#{INDENT * 3}</note>"
      ].compact
    end

    private

    attr_reader :plan, :lyric_writer, :grace_writer

    delegate :components_by_segment, :beam_annotations, :tuplet_marks, to: :plan

    # A rest emits one empty slot; a sounded voice event emits its pitches low to
    # high, so the lowest note leads with the beams and the rest carry <chord/>.
    # ensure_pitched_sounds has already rejected any unpitched sound, so pitches
    # covers every sound here.
    def component_lines(voice_event, component, beams, tuplet_mark, numbers)
      pitches = voice_event.rest? ? [nil] : voice_event.pitches.sort
      pitches.each_with_index.flat_map do |pitch, index|
        chord = index.positive?
        element_lines(voice_event, component, pitch, chord: chord, beams: chord ? [] : beams, tuplet_mark: tuplet_mark, **numbers)
      end
    end

    def render_error_class
      RenderError
    end

    # Element order inside <note> is fixed by the DTD: <chord/> comes first,
    # <voice> follows the ties and precedes <type>, and <staff> follows the
    # dots and precedes the beams. Each is omitted where it does not apply, so
    # a one-voice, one-staff part writes none of them.
    def element_lines(voice_event, component, pitch, chord:, beams:, tuplet_mark:, voice_number:, staff_number:)
      ties = ties(voice_event, component, pitch)
      [
        "#{INDENT * 3}<note>",
        ("#{INDENT * 4}<chord/>" if chord),
        *(pitch ? PitchWriter.lines(pitch) : ["#{INDENT * 4}<rest/>"]),
        "#{INDENT * 4}<duration>#{component.duration}</duration>",
        *tie_lines("tie", 4, ties),
        number_line("voice", voice_number),
        "#{INDENT * 4}<type>#{component.type}</type>",
        *Array.new(component.dots) { "#{INDENT * 4}<dot/>" },
        *tuplet_marks.time_modification_lines(tuplet_mark),
        number_line("staff", staff_number),
        *beams.map { |beam| %(#{INDENT * 4}<beam number="#{beam.number}">#{beam.type}</beam>) },
        *notations_lines([*tie_lines("tied", 5, ties), *(chord ? [] : lead_notation_lines(voice_event, component, tuplet_mark))]),
        *lyric_writer.lines(voice_event, component, chord: chord),
        "#{INDENT * 3}</note>"
      ].compact
    end

    # Rests take no ties; the links of a rest's tied chain render as
    # consecutive independent rests. Only the first component of a chain can
    # be tied into from a grace note.
    def ties(voice_event, component, pitch)
      return {} if voice_event.rest?

      {stop: component.tie_stop || GraceWriter.tied_into?(voice_event, pitch), start: component.tie_start}
    end

    # A rest carries no markings, but a phrase may begin or end on one.
    def lead_notation_lines(voice_event, component, tuplet_mark)
      [*slur_lines(voice_event, component), *tuplet_marks.tuplet_lines(tuplet_mark), *marking_lines(voice_event, component)]
    end

    # A stop on the voice event's last component, a start on its first, the
    # stop first where one slur ends and the next begins. A rest's components
    # are rests of their own, so it carries both on its first.
    def slur_lines(voice_event, component)
      numbers = plan.slur_numbers(voice_event.voice.part)
      stops = SlurNumbers.closing_component?(voice_event, component) ? numbers.stops_at(voice_event) : []
      starts = component.tie_stop ? [] : numbers.starts_at(voice_event)
      [*stops.map { |number| slur_line("stop", number) }, *starts.map { |number| slur_line("start", number) }]
    end

    # Markings ride only the first written fragment of a tied or bar-split
    # note, following LyricWriter's own-attack rule: every later component's
    # tie_stop is set.
    def marking_lines(voice_event, component)
      return [] if voice_event.rest? || component.tie_stop

      [
        *marking_group_lines("ornaments", voice_event.ornaments, MarkingElements.method(:ornament_element)),
        *marking_group_lines("articulations", voice_event.articulations, MarkingElements.method(:articulation_element)),
        *marking_group_lines("dynamics", Array(voice_event.note_dynamic), MarkingElements.method(:dynamic_element))
      ]
    end
  end
end
