# A module for musical instruments and their properties
module HeadMusic::Instruments; end

# The properties an instrument derives from its default notation staves:
# how many staves it uses, their clefs, whether it transposes, and whether it
# is pitched. These are a projection of the notation layer (a StaffScheme built
# from the default NotationStyle), separated from the instrument's identity so
# Instrument can delegate to one place rather than carry the staff logic itself.
class HeadMusic::Instruments::StaffProfile
  attr_reader :instrument

  def initialize(instrument)
    @instrument = instrument
  end

  def staff_schemes
    [default_staff_scheme]
  end

  def default_staff_scheme
    @default_staff_scheme ||= HeadMusic::Instruments::StaffScheme.new(
      key: "default",
      instrument: instrument,
      list: default_notation_staves_data
    )
  end

  def default_staves
    default_staff_scheme.staves
  end

  def default_clefs
    default_staves&.map(&:clef) || []
  end

  def sounding_transposition
    default_staves&.first&.sounding_transposition || 0
  end

  def transposing?
    sounding_transposition != 0
  end

  def transposing_at_the_octave?
    transposing? && sounding_transposition % 12 == 0
  end

  def single_staff?
    default_staves.length == 1
  end

  def multiple_staves?
    default_staves.length > 1
  end

  def pitched?
    return false if default_clefs.compact.uniq == [HeadMusic::Rudiment::Clef.get("neutral_clef")]

    default_clefs.any?
  end

  private

  # The raw staff-attribute list for this instrument's default notation,
  # resolved from the default NotationStyle. Referenced only inside a method
  # body, because the Notation module loads after Instruments.
  def default_notation_staves_data
    notation = HeadMusic::Notation::NotationStyle.default.notation_for(instrument)
    (notation&.staves || []).map(&:attributes)
  end
end
