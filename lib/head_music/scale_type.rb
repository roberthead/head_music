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

  class << self
    def ionian
      @ionian ||= new I
    end
    alias_method :major, :ionian
    alias_method :i, :ionian

    def dorian
      @dorian ||= new II
    end

    def phrygian
      @phrygian ||= new III
    end

    def lydian
      @lydian ||= new IV
    end

    def mixolydian
      @lydian ||= new V
    end

    def aeolian
      @aeolian ||= new VI
    end
    alias_method :minor, :aeolian
    alias_method :natural_minor, :aeolian

    def locrian
      @locrian ||= new VII
    end

    def harmonic_minor
      @harmonic_minor ||= new HARMONIC_MINOR
    end

    def melodic_minor
      @melodic_minor ||= new MELODIC_MINOR_ASCENDING, VI.reverse
    end

    def chromatic
      @chromatic ||= new CHROMATIC
    end
  end

  attr_reader :ascending_intervals, :descending_intervals

  def initialize(ascending, descending = nil)
    @ascending_intervals = ascending
    @descending_intervals = descending || ascending.reverse
  end

  def ==(other)
    self.state == other.state
  end

  def state
    [ascending_intervals, descending_intervals]
  end
end
