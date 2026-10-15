# A module for music rudiments
module HeadMusic::Rudiment; end

module HeadMusic::Rudiment::Rhythm
  PPQN = PULSES_PER_QUARTER_NOTE = 960
  SUBTICKS_PER_TICK = 240
  SUBTICKS_PER_WHOLE = PPQN * 4 * SUBTICKS_PER_TICK
end
