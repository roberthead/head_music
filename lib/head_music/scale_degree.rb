class HeadMusic::ScaleDegree
  include Comparable

  NAME_FOR_DIATONIC_DEGREE = [nil, 'tonic', 'supertonic', 'mediant', 'subdominant', 'dominant', 'submediant']

  attr_reader :key_signature, :spelling
  delegate :scale, to: :key_signature
  delegate :scale_type, to: :scale

  def initialize(key_signature, spelling)
    @key_signature = key_signature
    @spelling = Spelling.get(spelling)
  end

  def degree
    scale.letter_name_cycle.index(spelling.letter_name.to_s) + 1
  end

  def accidental
    spelling.accidental
    scale_degree_usual_spelling.accidental
    accidental_semitones = spelling.accidental && spelling.accidental.semitones || 0
    usual_accidental_semitones = scale_degree_usual_spelling.accidental && scale_degree_usual_spelling.accidental.semitones || 0
    Accidental.for_interval(accidental_semitones - usual_accidental_semitones)
  end

  def to_s
    "#{accidental}#{degree}"
  end

  def <=>(other)
    if other.is_a?(HeadMusic::ScaleDegree)
      [degree, accidental.semitones] <=> [other.degree, other.accidental.semitones]
    else
      to_s <=> other.to_s
    end
  end

  def name_for_degree
    if scale_type.diatonic?
      NAME_FOR_DIATONIC_DEGREE[degree] ||
      (scale_type.intervals.last == 1 || accidental == '#' ? 'leading tone' : 'subtonic')
    end
  end

  private

  def scale_degree_usual_spelling
    Spelling.get(scale.spellings[degree - 1])
  end
end
