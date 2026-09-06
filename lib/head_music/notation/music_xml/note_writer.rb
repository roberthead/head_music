require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the <note> elements a placement occupies.
  #
  # A placement becomes one <note> per tied component per sounding pitch: the
  # components come from the render plan's duration split, and a chord renders
  # as a lead note followed by its <chord/> members.
  class NoteWriter
    include XmlText
    include HeadMusic::Notation::PlacementValidation

    def initialize(plan)
      @plan = plan
      @lyric_writer = LyricWriter.new
    end

    # @param voice_number [Integer, nil] the <voice> a part's notes belong to,
    #   omitted for a part holding one voice
    # @param staff_number [Integer, nil] the <staff> the note is written on,
    #   omitted for a part on one staff
    def lines(placement, voice_number: nil, staff_number: nil)
      ensure_pitched_sounds(placement)

      components_by_placement[placement].each_with_index.flat_map do |component, component_index|
        beams = beam_annotations[[placement, component_index]] || []
        note_slots(placement).each_with_index.flat_map do |pitch, index|
          element_lines(
            placement, component, pitch: pitch, chord: index.positive?, beams: index.zero? ? beams : [],
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

    delegate :components_by_placement, :beam_annotations, to: :plan

    # A rest emits one empty slot; a sounded placement emits its pitches low to
    # high, so the lowest note leads and the rest carry <chord/>. ensure_pitched_sounds
    # has already rejected any unpitched sound, so pitches covers every sound here.
    def note_slots(placement)
      placement.rest? ? [nil] : placement.pitches.sort
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
    def element_lines(placement, component, pitch: nil, chord: false, beams: [], voice_number: nil, staff_number: nil)
      [
        "#{INDENT * 3}<note>",
        *(chord ? ["#{INDENT * 4}<chord/>"] : []),
        *(pitch ? pitch_lines(pitch) : ["#{INDENT * 4}<rest/>"]),
        "#{INDENT * 4}<duration>#{component.duration}</duration>",
        *tie_lines(placement, component),
        voice_number && "#{INDENT * 4}<voice>#{voice_number}</voice>",
        "#{INDENT * 4}<type>#{component.type}</type>",
        *Array.new(component.dots) { "#{INDENT * 4}<dot/>" },
        staff_number && "#{INDENT * 4}<staff>#{staff_number}</staff>",
        *beam_lines(beams),
        *notation_lines(placement, component),
        *lyric_writer.lines(placement, component, chord: chord),
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
    def tie_lines(placement, component)
      return [] if placement.rest?

      [
        component.tie_stop ? %(#{INDENT * 4}<tie type="stop"/>) : nil,
        component.tie_start ? %(#{INDENT * 4}<tie type="start"/>) : nil
      ].compact
    end

    def notation_lines(placement, component)
      return [] if placement.rest? || (!component.tie_start && !component.tie_stop)

      [
        "#{INDENT * 4}<notations>",
        component.tie_stop ? %(#{INDENT * 5}<tied type="stop"/>) : nil,
        component.tie_start ? %(#{INDENT * 5}<tied type="start"/>) : nil,
        "#{INDENT * 4}</notations>"
      ].compact
    end
  end
end
