class HeadMusic::Analysis::PitchSpeller
  # A tonal context on the line of fifths, with each pitch class classified once.
  class KeyCenter
    LineOfFifths = HeadMusic::Analysis::LineOfFifths
    Key = HeadMusic::Rudiment::Key
    Mode = HeadMusic::Rudiment::Mode

    NEAR_TIE = 2
    # Outside the key, a spelling takes at most one accidental.
    CHROMATIC_RANGE = (-8..12)
    CHROMATIC_CANDIDATES = (0..11).map { |pitch_class| CHROMATIC_RANGE.select { |index| LineOfFifths.pitch_class_of(index) == pitch_class } }.freeze
    MODE_SIGNATURES = {ionian: 0, dorian: -2, phrygian: -4, lydian: 1, mixolydian: -1, aeolian: -3, locrian: -5}.freeze

    attr_reader :center

    def self.for(tonal_context)
      case tonal_context
      when Key then for_key(tonal_context)
      when Mode then for_mode(tonal_context)
      else
        signature = tonal_context.num_sharps - tonal_context.num_flats
        new(signature: signature, center: signature + 2)
      end
    end

    def self.for_key(key)
      tonic = LineOfFifths.index_of(key.tonic_spelling)
      return new(signature: tonic, center: tonic + 2) if key.major?

      new(signature: tonic - 3, center: tonic, raised: [tonic + 3, tonic + 5])
    end

    def self.for_mode(mode)
      tonic = LineOfFifths.index_of(mode.tonic_spelling)
      signature = tonic + MODE_SIGNATURES.fetch(mode.mode_name)
      raised = (Mode::PARALLEL_QUALITIES[mode.mode_name] == :minor) ? [tonic + 3, tonic + 5] : []
      new(signature: signature, center: signature + 2, raised: raised)
    end

    private_class_method :for_key, :for_mode

    def initialize(signature:, center:, raised: [])
      @collection_start = signature - 1
      @center = center
      @raised = raised
      @choices = (0..11).map { |pitch_class| classify(pitch_class) }.freeze
    end

    # [rule, index] when the key decides, or [:near, [nearer, farther]].
    def choice(pitch_class)
      @choices[pitch_class]
    end

    private

    def classify(pitch_class)
      diatonic = @collection_start + (CHROMATIC_CANDIDATES[pitch_class].first - @collection_start) % 12
      return [:diatonic, diatonic] if diatonic <= @collection_start + 6

      raised = @raised.find { |index| LineOfFifths.pitch_class_of(index) == pitch_class }
      return [:raised, raised] if raised

      nearer, farther = CHROMATIC_CANDIDATES[pitch_class].sort_by { |index| [distance(index), -index] }
      return [:center, nearer] unless farther && distance(farther) - distance(nearer) <= NEAR_TIE

      [:near, [nearer, farther]]
    end

    def distance(index)
      (index - center).abs
    end
  end
end
