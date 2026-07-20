module HeadMusic::Notation; end

# The resolved notation for one instrument within a NotationStyle: its staves
# (each with a clef and sounding transposition) plus any recorded alternatives.
#
# This is a derived value object produced by NotationStyle#notation_for, not a
# catalog entry with its own factory. Alternatives are recorded data only —
# no selection behavior is implemented here (deferred to the Content layer).
class HeadMusic::Notation::InstrumentNotation
  include HeadMusic::ValueEquality

  attr_reader :instrument, :staves, :alternatives

  value_equality :instrument, :staves_attributes
  alias_method :eql?, :==

  def initialize(instrument:, data:)
    @instrument = instrument
    @staves = build_staves(data["staves"])
    @alternatives = build_staves(data["alternatives"])
    freeze
  end

  def clefs
    staves.map(&:clef)
  end

  def sounding_transposition
    staves.first&.sounding_transposition || 0
  end

  def single_staff?
    staves.length == 1
  end

  def multiple_staves?
    staves.length > 1
  end

  def hash
    [instrument.name_key, staves_attributes].hash
  end

  protected

  def staves_attributes
    staves.map(&:attributes)
  end

  private

  def build_staves(list)
    (list || []).map { |attributes| HeadMusic::Instruments::Staff.new(nil, attributes) }
  end
end
