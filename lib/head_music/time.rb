# frozen_string_literal: true

module HeadMusic
  # The Time module provides classes and methods to handle representations
  # of musical time and its relationship to clock time and SMPTE Time Code.
  #
  # This module enables synchronization between three time representations:
  # - Clock time: elapsed nanoseconds (source of truth)
  # - Musical position: bars:beats:ticks:subticks notation
  # - SMPTE timecode: hours:minutes:seconds:frames for video/audio sync
  #
  # @example Converting between time representations
  #   conductor = HeadMusic::Time::Conductor.new
  #   clock_pos = HeadMusic::Time::ClockPosition.new(1_000_000_000) # 1 second
  #   musical_pos = conductor.clock_to_musical(clock_pos)
  module Time
    # Ticks per quarter note value (MIDI standard)
    PPQN = PULSES_PER_QUARTER_NOTE = 960

    # Subticks provide finer resolution than ticks for precise timing
    SUBTICKS_PER_TICK = 240
  end
end

require_relative "time/clock_position"
require_relative "time/musical_position"
require_relative "time/smpte_timecode"
require_relative "time/meter_event"
require_relative "time/tempo_event"
require_relative "time/event_map_support"
require_relative "time/tempo_map"
require_relative "time/meter_map"
require_relative "time/conductor"
