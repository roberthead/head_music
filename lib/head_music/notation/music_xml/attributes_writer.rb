# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a measure's <attributes> element: everything in the first measure,
  # and thereafter only the changes that fall on the measure.
  class AttributesWriter
    include HeadMusic::Notation::XmlText

    CLEF_REGISTERS = {"G" => 4, "F" => 3, "C" => 4}.freeze

    delegate(
      :divisions, :bar_numbers, :measure_key_changes, :measure_time_changes,
      :first_measure_key, :first_measure_meter, :transposed?,
      to: :plan
    )

    def initialize(plan)
      @plan = plan
    end

    def lines(part, bar_number)
      inner = (bar_number == bar_numbers.first) ? first_measure_lines(part) : change_lines(part, bar_number)
      return [] if inner.empty?

      ["#{INDENT * 3}<attributes>", *inner, "#{INDENT * 3}</attributes>"]
    end

    private

    attr_reader :plan

    def first_measure_lines(part)
      [
        "#{INDENT * 4}<divisions>#{divisions}</divisions>",
        *key_lines(first_measure_key(part)),
        *time_lines(first_measure_meter),
        *staves_lines(part),
        *clef_lines(part.staff_system.staves) { |staff| clef_for(part, staff) },
        *transpose_lines(part.instrument_at(bar_numbers.first))
      ]
    end

    def change_lines(part, bar_number)
      [
        *key_lines(measure_key_changes(part)[bar_number]),
        *time_lines(measure_time_changes[bar_number]),
        *clef_lines(part.staff_system_at(bar_number).staves) { |staff| staff.clef_changes[bar_number] },
        *instrument_change_transpose_lines(part, bar_number)
      ]
    end

    # A change back to an instrument in C writes a <transpose> of nothing, since
    # a <transpose> stays in force until another replaces it.
    def instrument_change_transpose_lines(part, bar_number)
      return [] unless part.instrument_changes.key?(bar_number)

      transpose_lines(part.instrument_at(bar_number), part.instrument_at(bar_number - 1))
    end

    # <transpose> states sounding = written + transpose, the same convention the
    # instrument catalog states its sounding_transposition in. The octaves go in
    # <octave-change>, which is how publishers write a bass clarinet.
    def transpose_lines(instrument, previous = nil)
      return [] unless transposed?

      semitones = semitones(instrument)
      return [] if semitones.zero? && semitones(previous).zero?

      chromatic = semitones.remainder(12)
      octaves = (semitones - chromatic) / 12
      [
        "#{INDENT * 4}<transpose>",
        "#{INDENT * 5}<diatonic>#{diatonic_steps(chromatic)}</diatonic>",
        "#{INDENT * 5}<chromatic>#{chromatic}</chromatic>",
        (octaves.zero? ? nil : "#{INDENT * 5}<octave-change>#{octaves}</octave-change>"),
        "#{INDENT * 4}</transpose>"
      ].compact
    end

    def semitones(instrument)
      instrument&.sounding_transposition.to_i
    end

    def diatonic_steps(semitones)
      HeadMusic::Content::Layout::Transposition.for_semitones(semitones).diatonic_steps
    end

    # <staves> is omitted for the single-staff part, where it would be noise,
    # and <part-symbol> for a brace, which is what it defaults to.
    def staves_lines(part)
      system = part.staff_system
      return [] unless system.length > 1

      symbol = (system.bracket == :brace) ? nil : "#{INDENT * 4}<part-symbol>#{system.bracket}</part-symbol>"
      ["#{INDENT * 4}<staves>#{system.length}</staves>", symbol].compact
    end

    def key_lines(key)
      return [] unless key

      [
        "#{INDENT * 4}<key>",
        "#{INDENT * 5}<fifths>#{key[:fifths]}</fifths>",
        key[:mode] && "#{INDENT * 5}<mode>#{key[:mode]}</mode>",
        "#{INDENT * 4}</key>"
      ].compact
    end

    def time_lines(meter)
      return [] unless meter

      symbol = meter.symbol && %( symbol="#{meter.symbol}")
      [
        "#{INDENT * 4}<time#{symbol}>",
        "#{INDENT * 5}<beats>#{meter.top_number}</beats>",
        "#{INDENT * 5}<beat-type>#{meter.bottom_number}</beat-type>",
        "#{INDENT * 4}</time>"
      ]
    end

    # An authored clef wins; the selector is the fallback for a part whose staves
    # were never authored. It reads a *voice's* pitch range, which is why the
    # fallback lives here, where a voice is in scope, rather than on the staff.
    def clef_for(part, staff)
      staff.clef_at(bar_numbers.first) || HeadMusic::Notation::ClefSelector.for(part.voices.first)
    end

    def clef_lines(staves)
      staves.each_with_index.flat_map do |staff, index|
        clef = yield(staff)
        clef ? clef_element_lines(clef, clef_number(staves, index)) : []
      end
    end

    def clef_number(staves, index)
      (staves.length > 1) ? %( number="#{index + 1}") : ""
    end

    # The octave change is how far the clef's pitch sits from its sign's usual
    # register, as the tenor's treble clef sits an octave below G4.
    def clef_element_lines(clef, number)
      pitch = clef.pitch
      sign = pitch.letter_name
      octave_change = pitch.register - CLEF_REGISTERS.fetch(sign.to_s)
      [
        "#{INDENT * 4}<clef#{number}>",
        "#{INDENT * 5}<sign>#{sign}</sign>",
        "#{INDENT * 5}<line>#{clef.line}</line>",
        octave_change.zero? ? nil : "#{INDENT * 5}<clef-octave-change>#{octave_change}</clef-octave-change>",
        "#{INDENT * 4}</clef>"
      ].compact
    end
  end
end
