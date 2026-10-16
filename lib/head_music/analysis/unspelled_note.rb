# A module for musical analysis
module HeadMusic::Analysis; end

# A key number sounding at a time, before it is spelled as a pitch. The onset
# and duration are Rational whole notes, with the first downbeat at 0, as MIDI
# export lays them out. The voice is any hashable label, or nil.
HeadMusic::Analysis::UnspelledNote = Data.define(:number, :onset, :duration, :voice) do
  def initialize(number:, onset:, duration:, voice: nil)
    super(number: Integer(number), onset: onset.to_r, duration: duration.to_r, voice: voice)
  end
end
