require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a measure's <attributes> element: everything in the first measure,
  # and thereafter only the changes that fall on the measure.
  class AttributesWriter
    include XmlText

    delegate(
      :divisions, :bar_numbers, :measure_key_changes, :measure_time_changes,
      :first_measure_key, :first_measure_meter, :transposed?,
      to: :plan
    )

    def initialize(plan)
      @plan = plan
    end

    def lines(part, bar_number)
      return first_measure_lines(part) if bar_number == bar_numbers.first

      key = measure_key_changes(part)[bar_number]
      meter = measure_time_changes[bar_number]
      transpose = instrument_change_transpose_lines(part, bar_number)
      return [] unless key || meter || transpose.any?

      [
        "#{INDENT * 3}<attributes>",
        *(key ? key_lines(key) : []),
        *(meter ? time_lines(meter) : []),
        *transpose,
        "#{INDENT * 3}</attributes>"
      ]
    end

    private

    attr_reader :plan

    def first_measure_lines(part)
      [
        "#{INDENT * 3}<attributes>",
        "#{INDENT * 4}<divisions>#{divisions}</divisions>",
        *key_lines(first_measure_key(part)),
        *time_lines(first_measure_meter),
        *staves_lines(part),
        *clef_lines(part),
        *transpose_lines(part.instrument_at(bar_numbers.first)),
        "#{INDENT * 3}</attributes>"
      ]
    end

    def instrument_change_transpose_lines(part, bar_number)
      return [] unless part.instrument_changes.key?(bar_number)

      transpose_lines(part.instrument_at(bar_number))
    end

    # <transpose> states sounding = written + transpose, the same convention the
    # instrument catalog states its sounding_transposition in. The octaves go in
    # <octave-change>, which is how publishers write a bass clarinet.
    def transpose_lines(instrument)
      return [] unless transposed?

      semitones = instrument&.sounding_transposition.to_i
      return [] if semitones.zero?

      sign = semitones.negative? ? -1 : 1
      octaves, chromatic = semitones.abs.divmod(12)
      [
        "#{INDENT * 4}<transpose>",
        "#{INDENT * 5}<diatonic>#{diatonic_steps(sign * chromatic)}</diatonic>",
        "#{INDENT * 5}<chromatic>#{sign * chromatic}</chromatic>",
        (octaves.zero? ? nil : "#{INDENT * 5}<octave-change>#{sign * octaves}</octave-change>"),
        "#{INDENT * 4}</transpose>"
      ].compact
    end

    def diatonic_steps(semitones)
      HeadMusic::Content::Layout::Transposition.for_semitones(semitones).diatonic_steps
    end

    # <staves> is omitted for the single-staff part, where it would be noise.
    def staves_lines(part)
      count = part.staff_system.length
      (count > 1) ? ["#{INDENT * 4}<staves>#{count}</staves>"] : []
    end

    def key_lines(key)
      [
        "#{INDENT * 4}<key>",
        "#{INDENT * 5}<fifths>#{key[:fifths]}</fifths>",
        key[:mode] && "#{INDENT * 5}<mode>#{key[:mode]}</mode>",
        "#{INDENT * 4}</key>"
      ].compact
    end

    def time_lines(meter)
      [
        "#{INDENT * 4}<time>",
        "#{INDENT * 5}<beats>#{meter.top_number}</beats>",
        "#{INDENT * 5}<beat-type>#{meter.bottom_number}</beat-type>",
        "#{INDENT * 4}</time>"
      ]
    end

    # An authored clef wins; the selector is the fallback for a part whose staves
    # were never authored. It reads a *voice's* pitch range, which is why the
    # fallback lives here, where a voice is in scope, rather than on the staff.
    def clef_lines(part)
      staves = part.staff_system.staves
      staves.each_with_index.flat_map do |staff, index|
        number = (staves.length > 1) ? %( number="#{index + 1}") : ""
        clef_element_lines(clef_for(part, staff), number)
      end
    end

    def clef_for(part, staff)
      staff.clef_at(bar_numbers.first) || HeadMusic::Notation::ClefSelector.for(part.voices.first)
    end

    def clef_element_lines(clef, number)
      [
        "#{INDENT * 4}<clef#{number}>",
        "#{INDENT * 5}<sign>#{clef.pitch.letter_name}</sign>",
        "#{INDENT * 5}<line>#{clef.line}</line>",
        "#{INDENT * 4}</clef>"
      ]
    end
  end
end
