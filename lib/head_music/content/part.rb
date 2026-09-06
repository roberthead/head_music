# A module for musical content
module HeadMusic::Content; end

# A part is one player's music within one flow.
#
# The player is optional: a part with no player is simply a staff of music,
# which is what an ABC voice or a LilyPond staff is on import. The flow is not
# optional. Strip the flow and a part has no timeline; strip the project and it
# has no player; what remains is a voice, which the gem already has.
class HeadMusic::Content::Part
  attr_reader :flow, :voices
  attr_accessor :player

  def initialize(flow:, player: nil, instrument: nil, staff_system: nil)
    raise ArgumentError, "a part belongs to a flow" if flow.nil?

    @flow = flow
    @player = player
    @voices = []
    # Both maps answer nil where nothing was authored, rather than seeding a
    # default. Seeding an instrument would be a guess, and the two commonest
    # cases in this gem -- a counterpoint part and a standalone flow -- have no
    # instrument at all. A staff system falls back to one staff instead.
    @instrument_map = HeadMusic::Time::EventMap.new(default: instrument && HeadMusic::Instruments::Instrument.get(instrument))
    @staff_system_map = HeadMusic::Time::EventMap.new(default: staff_system)
  end

  # @return [HeadMusic::Instruments::Instrument, nil] nil for a part that was
  #   never given one, which is most of them
  def instrument_at(bar_number)
    @instrument_map.at(downbeat_of(bar_number))
  end

  def instrument
    instrument_at(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
  end

  def change_instrument(bar_number, instrument)
    @instrument_map.add(downbeat_of(bar_number), HeadMusic::Instruments::Instrument.get(instrument)).value
  end

  def instrument_changes
    changes_by_bar(@instrument_map)
  end

  # Every instrument this part ever plays, in the order it first plays them.
  def instruments
    ([instrument] + instrument_changes.values).compact.uniq
  end

  # @return [HeadMusic::Content::StaffSystem] never nil: a part with no
  #   authored staves is written on one staff
  def staff_system_at(bar_number)
    @staff_system_map.at(downbeat_of(bar_number)) || default_staff_system
  end

  def staff_system
    staff_system_at(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
  end

  def change_staff_system(bar_number, staff_system)
    @staff_system_map.add(downbeat_of(bar_number), staff_system).value
  end

  def staff_system_changes
    changes_by_bar(@staff_system_map)
  end

  def add_voice(role: nil)
    HeadMusic::Content::Voice.new(part: self, role: role)
  end

  # @api private the one place a voice joins a part
  def attach(voice)
    @voices << voice
    voice
  end

  def player?
    !player.nil?
  end

  def to_s
    [player&.name, "#{voices.length} #{(voices.length == 1) ? "voice" : "voices"}"].compact.join(": ")
  end

  # Sparse: a part with no instrument and no authored staves serializes as its
  # voices alone, which is what every part of a counterpoint exercise is.
  def to_h
    hash = {"voices" => voices.map(&:to_h)}
    hash["instrument"] = instrument.name if instrument
    changes = instrument_changes.map { |bar_number, value| {"number" => bar_number, "instrument" => value.name} }
    hash["instrument_changes"] = changes unless changes.empty?
    hash["staff_system"] = staff_system.to_h if authored_staff_system?
    hash
  end

  private

  # The fallback system is not authored and so is not serialized: reading a
  # document back must leave the part with the same absent system it had, not
  # with a one-staff system someone appears to have chosen.
  def authored_staff_system?
    !@staff_system_map.at(downbeat_of(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)).nil?
  end

  # Memoized so that a part answers the same staff object every time, which is
  # what lets a voice's staff assignment be compared by identity.
  def default_staff_system
    @default_staff_system ||= HeadMusic::Content::StaffSystem.single_staff
  end

  def changes_by_bar(map)
    map.events.to_h { |event| [event.position.bar, event.value] }
  end

  def downbeat_of(bar_number)
    HeadMusic::Time::MusicalPosition.new(bar_number, HeadMusic::Time::MusicalPosition::FIRST_COUNT, 0, 0)
  end
end
