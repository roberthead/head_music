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

  MODE_NAMES = {
    i: [:ionian, :major],
    ii: [:dorian],
    iii: [:phrygian],
    iv: [:lydian],
    v: [:mixolydian],
    vi: [:aeolian, :minor, :natural_minor],
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

  CHROMATIC = [H, H, H, H, H, H, H, H, H, H, H, H]
  SCALE_TYPES[:chromatic] = { ascending: CHROMATIC }

  MINOR_PENTATONIC = [3, 2, 2, 3, 2]
  SCALE_TYPES[:minor_pentatonic] = { ascending: MINOR_PENTATONIC, parent_name: :minor }
  SCALE_TYPES[:major_pentatonic] = { ascending: MINOR_PENTATONIC.rotate, parent_name: :major }
  SCALE_TYPES[:egyptian_pentatonic] = { ascending: MINOR_PENTATONIC.rotate(2), parent_name: :minor }
  SCALE_TYPES[:blues_minor_pentatonic] = { ascending: MINOR_PENTATONIC.rotate(3), parent_name: :minor }
  SCALE_TYPES[:blues_major_pentatonic] = { ascending: MINOR_PENTATONIC.rotate(4), parent_name: :major }

  # exotic scales
  SCALE_TYPES[:octatonic] = { ascending: [W, H, W, H, W, H, W, H] }
  SCALE_TYPES[:whole_tone] = { ascending: [W, W, W, W, W, W] }

  class << self
    SCALE_TYPES.keys.each do |name|
      define_method(name) do
        self.get(name)
      end
    end
  end

  def self.get(name)
    @scale_types ||= {}
    identifier = HeadMusic::Utilities::HashKey.for(name)
    attributes = SCALE_TYPES[identifier]
    @scale_types[identifier] ||= new(identifier, attributes)
  end

  def self.default
    get(:major)
  end

  attr_reader :name, :ascending_intervals, :descending_intervals, :parent_name
  alias_method :intervals, :ascending_intervals

  delegate :to_s, to: :name

  def initialize(name, attributes)
    @name = name
    @ascending_intervals = attributes[:ascending]
    @descending_intervals = attributes[:descending] || ascending_intervals.reverse
    @parent_name = attributes[:parent_name]
  end

  def ==(other)
    self.state == other.state
  end

  def state
    [ascending_intervals, descending_intervals]
  end

  def parent
    @parent ||= self.class.get(parent_name) if parent_name
  end
end
