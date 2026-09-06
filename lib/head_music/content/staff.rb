# A module for musical content
module HeadMusic::Content; end

# A staff in a part: how many lines it has, what clef is in force on it at any
# moment, and -- for a percussion staff -- which catalog staff it realizes.
#
# This is the *instance* layer. HeadMusic::Instruments::Staff is the catalog
# layer: what a piano's staves are, read from YAML. A content staff references
# one rather than re-implementing it, because the catalog class already owns
# the position-to-instrument mappings a percussion staff needs.
class HeadMusic::Content::Staff
  DEFAULT_LINE_COUNT = 5

  attr_reader :line_count, :instruments_staff

  # @param clef [HeadMusic::Rudiment::Clef, String, Symbol, nil] the clef the
  #   staff opens with; nil leaves the choice to the writers, which fall back
  #   to inferring one from a voice's range
  # @param instruments_staff [HeadMusic::Instruments::Staff, nil] the catalog
  #   staff this realizes, for percussion mapping
  def initialize(clef: nil, line_count: DEFAULT_LINE_COUNT, instruments_staff: nil)
    @line_count = line_count
    @instruments_staff = instruments_staff
    @clef_map = HeadMusic::Time::EventMap.new(default: clef && HeadMusic::Rudiment::Clef.get(clef))
  end

  # The clef in force at a bar, or nil where none was authored.
  #
  # Nil rather than a guess: choosing a clef from a voice's pitch range needs a
  # voice, and a staff has no back-reference to one. The writers hold that
  # fallback, which is where the voice is in scope.
  def clef_at(bar_number)
    @clef_map.at(downbeat_of(bar_number))
  end

  def clef
    clef_at(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
  end

  def change_clef(bar_number, clef)
    @clef_map.add(downbeat_of(bar_number), HeadMusic::Rudiment::Clef.get(clef)).value
  end

  def clef_changes
    @clef_map.events.to_h { |event| [event.position.bar, event.value] }
  end

  # @return [HeadMusic::Rudiment::Pitch, nil] what a percussion position sounds
  def instrument_for_position(position_index)
    instruments_staff&.instrument_for_position(position_index)
  end

  def to_s
    [clef, "#{line_count}-line"].compact.join(" ")
  end

  # A null clef is a staff whose clef was never authored, which the writers
  # infer from a voice's range instead. It is a real state, not a missing one.
  def to_h
    hash = {"clef" => clef&.name_key&.to_s}
    changes = clef_changes.map { |bar_number, value| {"number" => bar_number, "clef" => value.name_key.to_s} }
    hash["clef_changes"] = changes unless changes.empty?
    hash
  end

  private

  def downbeat_of(bar_number)
    HeadMusic::Time::MusicalPosition.new(bar_number, HeadMusic::Time::MusicalPosition::FIRST_COUNT, 0, 0)
  end
end
