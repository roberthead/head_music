module HeadMusic::Notation::MEI
  # What the opening <scoreDef> states: the key and meter, each read on the
  # <scoreDef>, else on the first <staffDef> that states one, as MuseScore
  # puts its meter only on staff definitions; and the tempo of its
  # @midi.bpm. A transposing staff's key is the written one, so the score's
  # sounds its @trans.* away.
  class OpeningValues
    attr_reader :score_def

    def initialize(score_def, groups, editorial)
      @score_def = score_def
      @groups = groups
      @editorial = editorial
    end

    def key
      @key ||= first_stated { |element| concert_key(element) } || ScoreDefValues::Key.new(0, nil, nil)
    end

    def meter
      @meter ||= first_stated { |element| ScoreDefValues.meter(element, @editorial) } || HeadMusic::Rudiment::Meter.default
    end

    def tempo
      @tempo ||= score_def && ScoreDefValues.tempo(score_def, element: score_def)
    end

    private

    # An interval moves a key along the circle of fifths by seven fifths a
    # semitone less twelve a diatonic step, whatever its octaves.
    def concert_key(element)
      key = ScoreDefValues.key(element, @editorial)
      step = key && element.name == "staffDef" && StaffState.transposition(element)
      return key unless step

      ScoreDefValues::Key.new(key.fifths + (7 * step.chromatic) - (12 * step.diatonic), key.mode, nil)
    end

    def first_stated
      [score_def, *@groups.staff_numbers.map { |number| @groups.staff_def(number) }].compact.each do |element|
        value = yield(element)
        return value if value
      end
      nil
    end
  end
end
