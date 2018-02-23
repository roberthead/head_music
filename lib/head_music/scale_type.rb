# frozen_string_literal: true

# A ScaleType represents a particular scale pattern, such as major, lydian, or minor pentatonic.
class HeadMusic::ScaleType
  H = 1 # whole step
  W = 2 # half step

  # Modal
  I = [W, W, H, W, W, W, H].freeze
  II = I.rotate
  III = I.rotate(2)
  IV = I.rotate(3)
  V = I.rotate(4)
  VI = I.rotate(5)
  VII = I.rotate(6)

  # Tonal
  HARMONIC_MINOR = [W, H, W, W, H, 3, H].freeze
  MELODIC_MINOR_ASCENDING = [W, H, W, W, W, W, H].freeze

  MODE_NAMES = {
    i: %i[ionian major],
    ii: [:dorian],
    iii: [:phrygian],
    iv: [:lydian],
    v: [:mixolydian],
    vi: %i[aeolian minor natural_minor],
    vii: [:locrian],
  }.freeze

  CHROMATIC = [H, H, H, H, H, H, H, H, H, H, H, H].freeze

  MINOR_PENTATONIC = [3, 2, 2, 3, 2].freeze

  def self._modes
    {}.tap do |modes|
      MODE_NAMES.each do |roman_numeral, aliases|
        intervals = { ascending: const_get(roman_numeral.upcase) }
        modes[roman_numeral] = intervals
        aliases.each { |name| modes[name] = intervals }
      end
    end
  end

  def self._minor_scales
    {
      harmonic_minor: { ascending: HARMONIC_MINOR },
      melodic_minor: { ascending: MELODIC_MINOR_ASCENDING, descending: VI.reverse },
    }
  end

  def self._chromatic_scales
    { chromatic: { ascending: CHROMATIC } }
  end

  def self._pentatonic_scales
    {
      minor_pentatonic: { ascending: MINOR_PENTATONIC, parent_name: :minor },
      major_pentatonic: { ascending: MINOR_PENTATONIC.rotate, parent_name: :major },
      egyptian_pentatonic: { ascending: MINOR_PENTATONIC.rotate(2), parent_name: :minor },
      blues_minor_pentatonic: { ascending: MINOR_PENTATONIC.rotate(3), parent_name: :minor },
      blues_major_pentatonic: { ascending: MINOR_PENTATONIC.rotate(4), parent_name: :major },
    }
  end

  def self._exotic_scales
    {
      octatonic: { ascending: [W, H, W, H, W, H, W, H] },
      whole_tone: { ascending: [W, W, W, W, W, W] },
    }
  end

  SCALE_TYPES = {}.tap do |scales|
    scales.merge!(_modes)
    scales.merge!(_minor_scales)
    scales.merge!(_chromatic_scales)
    scales.merge!(_pentatonic_scales)
    scales.merge!(_exotic_scales)
  end.freeze

  class << self
    SCALE_TYPES.each_key do |name|
      define_method(name) do
        get(name)
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
  alias intervals ascending_intervals

  delegate :to_s, to: :name

  def initialize(name, attributes)
    @name = name
    @ascending_intervals = attributes[:ascending]
    @descending_intervals = attributes[:descending] || ascending_intervals.reverse
    @parent_name = attributes[:parent_name]
  end

  def ==(other)
    state == other.state
  end

  def state
    [ascending_intervals, descending_intervals]
  end

  def parent
    @parent ||= self.class.get(parent_name) if parent_name
  end

  def diatonic?
    intervals.length == 7
  end

  def whole_tone?
    intervals.length == 6 && intervals.uniq == [2]
  end

  def pentatonic?
    intervals.length == 5
  end

  def chromatic?
    intervals.length == 12
  end
end
