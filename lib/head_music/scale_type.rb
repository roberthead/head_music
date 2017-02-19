class HeadMusic::ScaleType
  H = 1 # whole step
  W = 2 # half step
  WH = W + H # augmented second

  # Modal
  I = [W, W, H, W, W, W, H]
  II = I.rotate
  III = I.rotate(2)
  IV = I.rotate(3)
  V = I.rotate(4)
  VI = I.rotate(5)
  VII = I.rotate(6)

  # Tonal
  HARMONIC_MINOR = [W, H, W, W, H, WH, H]
  MELODIC_MINOR_ASCENDING = [W, H, W, W, W, W, H]

  CHROMATIC = [H, H, H, H, H, H, H, H, H, H, H, H]
  MINOR_PENTATONIC = [3, 2, 2, 3, 2]
  MAJOR_PENTATONIC = MINOR_PENTATONIC.rotate

  MODE_NAMES = {
    i: [:ionian, :major, :maj],
    ii: [:dorian],
    iii: [:phrygian],
    iv: [:lydian],
    v: [:mixolydian],
    vi: [:aeolian, :minor, :natural_minor, :min],
    vii: [:locrian],
  }
  SCALE_TYPES = {}
  MODE_NAMES.each do |roman_numeral, aliases|
    intervals = { ascending: const_get(roman_numeral.upcase) }
    SCALE_TYPES[roman_numeral] = intervals
    aliases.each do |name|
      SCALE_TYPES[name.to_sym] = intervals
    end
  end
  SCALE_TYPES[:harmonic_minor] = { ascending: HARMONIC_MINOR }
  SCALE_TYPES[:melodic_minor] = { ascending: MELODIC_MINOR_ASCENDING, descending: VI.reverse }

  SCALE_TYPES[:chromatic] = { ascending: CHROMATIC }

  SCALE_TYPES[:minor_pentatonic] = { ascending: MINOR_PENTATONIC }
  SCALE_TYPES[:major_pentatonic] = { ascending: MAJOR_PENTATONIC }

  SCALE_TYPES[:octatonic] = { ascending: [W, H, W, H, W, H, W, H] }
  SCALE_TYPES[:whole_tone] = { ascending: [W, W, W, W, W, W] }
  SCALE_TYPES[:monotonic] = { ascending: [12] }

  class << self
    SCALE_TYPES.keys.each do |name|
      define_method(name) do
        self.get(name)
      end
    end
  end

  def self.get(name)
    @scale_types ||= {}
    name = name.to_s.to_sym
    intervals = SCALE_TYPES[name]
    @scale_types[name] ||= new(name, intervals[:ascending], intervals[:descending])
  end

  attr_reader :name, :ascending_intervals, :descending_intervals
  delegate :to_s, to: :name
  alias_method :intervals, :ascending_intervals

  def initialize(name, ascending_intervals, descending_intervals = nil)
    @name = name
    @ascending_intervals = ascending_intervals
    @descending_intervals = descending_intervals || ascending_intervals.reverse
  end

  def ==(other)
    self.state == other.state
  end

  def state
    [ascending_intervals, descending_intervals]
  end
end
