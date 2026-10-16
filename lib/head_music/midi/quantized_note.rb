module HeadMusic::MIDI
  # A note's key number and its onset and release snapped to the grid, in
  # Rational whole notes from tick 0.
  QuantizedNote = Data.define(:part_key, :key, :onset, :release)
end
