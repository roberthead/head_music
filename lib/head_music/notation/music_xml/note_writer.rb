require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the <note> elements a voice event occupies.
  #
  # A voice event becomes one <note> per tied component per sounding pitch in
  # each bar it sounds in: the components come from the render plan's duration
  # split, and a chord renders as a lead note followed by its <chord/> members.
  class NoteWriter
    include XmlText
    include HeadMusic::Notation::VoiceEventValidation

    def initialize(plan)
      @plan = plan
      @lyric_writer = LyricWriter.new
    end

    # @param voice_number [Integer, nil] the <voice> a part's notes belong to,
    #   omitted for a part holding one voice
    # @param staff_number [Integer, nil] the <staff> the note is written on,
    #   omitted for a part on one staff
    def lines(segment, voice_number: nil, staff_number: nil)
      voice_event = segment.voice_event
      ensure_pitched_sounds(voice_event)

      components_by_segment[segment].each_with_index.flat_map do |component, component_index|
        beams = beam_annotations[[segment, component_index]] || []
        note_slots(voice_event).each_with_index.flat_map do |pitch, index|
          element_lines(
            voice_event, component, pitch: pitch, chord: index.positive?, beams: index.zero? ? beams : [],
            voice_number: voice_number, staff_number: staff_number
          )
        end
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
        voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>",
        staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>",
        "#{INDENT * 3}</note>"
      ].compact
    end

    private

    attr_reader :plan, :lyric_writer

    delegate :components_by_segment, :beam_annotations, to: :plan

    # A rest emits one empty slot; a sounded voice event emits its pitches low to
    # high, so the lowest note leads and the rest carry <chord/>. ensure_pitched_sounds
    # has already rejected any unpitched sound, so pitches covers every sound here.
    def note_slots(voice_event)
      voice_event.rest? ? [nil] : voice_event.pitches.sort
    end

    def render_error_class
      RenderError
    end

    # A chord note carries <chord/> as its first child, before <pitch>, marking
    # it as sounding with the preceding note; the lead note (and every single
    # note and rest) omits it, so this path stays byte-identical for those.
    # Element order inside <note> is fixed by the DTD: <voice> follows the ties
    # and precedes <type>, and <staff> follows the dots and precedes the beams.
    # Both are omitted entirely for the one-voice, one-staff part that every
    # existing document is made of, which is what keeps this byte-identical.
    def element_lines(voice_event, component, pitch: nil, chord: false, beams: [], voice_number: nil, staff_number: nil)
      [
        "#{INDENT * 3}<note>",
        *(chord ? ["#{INDENT * 4}<chord/>"] : []),
        *(pitch ? pitch_lines(pitch) : ["#{INDENT * 4}<rest/>"]),
        "#{INDENT * 4}<duration>#{component.duration}</duration>",
        *tie_lines(voice_event, component),
        voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>",
        "#{INDENT * 4}<type>#{component.type}</type>",
        *Array.new(component.dots) { "#{INDENT * 4}<dot/>" },
        staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>",
        *beam_lines(beams),
        *notation_lines(voice_event, component, chord: chord),
        *lyric_writer.lines(voice_event, component, chord: chord),
        "#{INDENT * 3}</note>"
      ].compact
    end

    def beam_lines(beams)
      beams.map { |beam| %(#{INDENT * 4}<beam number="#{beam.number}">#{beam.type}</beam>) }
    end

    def pitch_lines(pitch)
      attributes = PitchWriter.attributes(pitch)
      [
        "#{INDENT * 4}<pitch>",
        "#{INDENT * 5}<step>#{attributes[:step]}</step>",
        attributes[:alter] && "#{INDENT * 5}<alter>#{attributes[:alter]}</alter>",
        "#{INDENT * 5}<octave>#{attributes[:octave]}</octave>",
        "#{INDENT * 4}</pitch>"
      ].compact
    end

    # Rests take no tie elements; the links of a rest's tied chain render as
    # consecutive independent rests.
    def tie_lines(voice_event, component)
      return [] if voice_event.rest?

      tie_elements("tie", 4, component)
    end

    # A <tie> is heard and a <tied> is drawn; each stops before it starts.
    def tie_elements(tag, depth, component)
      {"stop" => component.tie_stop, "start" => component.tie_start}.filter_map do |type, present|
        %(#{INDENT * depth}<#{tag} type="#{type}"/>) if present
      end
    end

    # A rest carries no ties or markings, but a phrase may begin or end on one.
    def notation_lines(voice_event, component, chord:)
      lines = [
        *(voice_event.rest? ? [] : tie_elements("tied", 5, component)),
        *slur_lines(voice_event, component, chord: chord),
        *(voice_event.rest? ? [] : marking_lines(voice_event, component, chord: chord))
      ]
      return [] if lines.empty?

      ["#{INDENT * 4}<notations>", *lines, "#{INDENT * 4}</notations>"]
    end

    # On the chord's first note: a stop on the voice event's last component,
    # a start on its first, the stop first where one slur ends and the next
    # begins. A rest's components are rests of their own, so it carries both
    # on its first.
    def slur_lines(voice_event, component, chord:)
      return [] if chord

      numbers = plan.slur_numbers(voice_event.voice.part)
      stops = SlurNumbers.closing_component?(voice_event, component) ? numbers.stops_at(voice_event) : []
      starts = component.tie_stop ? [] : numbers.starts_at(voice_event)
      [*stops.map { |number| slur_line("stop", number) }, *starts.map { |number| slur_line("start", number) }]
    end

    def slur_line(type, number)
      %(#{INDENT * 5}<slur type="#{type}" number="#{number}"/>)
    end

    # Markings ride the chord's first note (the one without <chord/>) and
    # only the first written fragment of a tied or bar-split note, following
    # LyricWriter's own-attack rule: every later component's tie_stop is set.
    def marking_lines(voice_event, component, chord:)
      return [] if chord || component.tie_stop

      [
        *marking_group_lines("ornaments", voice_event.ornaments, MarkingWriter.method(:ornament_element)),
        *marking_group_lines("articulations", voice_event.articulations, MarkingWriter.method(:articulation_element)),
        *dynamic_notation_lines(voice_event.note_dynamic)
      ]
    end

    def marking_group_lines(tag, markings, element_for)
      return [] if markings.empty?

      [
        "#{INDENT * 5}<#{tag}>",
        *markings.map { |marking| "#{INDENT * 6}<#{element_for.call(marking)}/>" },
        "#{INDENT * 5}</#{tag}>"
      ]
    end

    def dynamic_notation_lines(note_dynamic)
      return [] unless note_dynamic

      [
        "#{INDENT * 5}<dynamics>",
        "#{INDENT * 6}<#{MarkingWriter.dynamic_element(note_dynamic)}/>",
        "#{INDENT * 5}</dynamics>"
      ]
    end
  end
end
