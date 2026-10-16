# A module for musical analysis
module HeadMusic::Analysis; end

# A key in force from the downbeat of a bar, at that onset in whole notes.
HeadMusic::Analysis::KeyRegion = Data.define(:bar_number, :onset, :key)
