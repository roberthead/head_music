module HeadMusic::Instruments; end

# An option for an instrument configuration.
#
# Examples:
#   - Piccolo trumpet leadpipe: "a" option with transposition_semitones: -1
#   - Bass trombone F attachment: "engaged" option with lowest_pitch_semitones: -6
#   - Trumpet mute: "straight", "cup", "harmon" options (no pitch effects)
class HeadMusic::Instruments::InstrumentConfigurationOption
  attr_reader :name_key, :default, :transposition_semitones, :lowest_pitch_semitones

  def initialize(name_key:, default: false, transposition_semitones: nil, lowest_pitch_semitones: nil)
    @name_key = name_key.to_sym
    @default = default
    @transposition_semitones = transposition_semitones
    @lowest_pitch_semitones = lowest_pitch_semitones
  end

  def default?
    @default == true
  end

  def affects_transposition?
    !transposition_semitones.nil?
  end

  def affects_range?
    !lowest_pitch_semitones.nil?
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    name_key == other.name_key
  end

  def to_s
    name_key.to_s
  end
end
