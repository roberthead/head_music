# A module for musical analysis
module HeadMusic::Analysis; end

# A Dyad is a two-pitch combination that can imply various chords.
# It analyzes the harmonic implications of two pitches sounding together.
class HeadMusic::Analysis::Dyad
  attr_reader :pitch1, :pitch2, :key

  def initialize(pitch1, pitch2, key: nil)
    @pitch1, @pitch2 = [
      HeadMusic::Rudiment::Pitch.get(pitch1),
      HeadMusic::Rudiment::Pitch.get(pitch2)
    ].sort
    @key = key ? HeadMusic::Rudiment::Key.get(key) : nil
  end

  def interval
    @interval ||= HeadMusic::Analysis::DiatonicInterval.new(lower_pitch, upper_pitch)
  end

  def pitches
    [pitch1, pitch2]
  end

  def lower_pitch
    @lower_pitch ||= [pitch1, pitch2].min
  end

  def upper_pitch
    @upper_pitch ||= [pitch1, pitch2].max
  end

  def possible_trichords
    chord_implication.trichords
  end

  def possible_triads
    @possible_triads ||= possible_trichords.select(&:triad?)
  end

  def possible_seventh_chords
    chord_implication.seventh_chords
  end

  def enharmonic_respellings
    @enharmonic_respellings ||= generate_enharmonic_respellings
  end

  def to_s
    "#{pitch1} - #{pitch2}"
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? interval.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    interval.respond_to?(method_name)
  end

  private

  def chord_implication
    @chord_implication ||= ChordImplication.new([lower_pitch.pitch_class, upper_pitch.pitch_class], key)
  end

  def generate_enharmonic_respellings
    lower_equivalents = enharmonic_equivalents_for(pitch1)
    upper_equivalents = enharmonic_equivalents_for(pitch2)

    lower_equivalents.product(upper_equivalents)
      .reject { |lower, upper| original_spelling?(lower, upper) }
      .map { |lower, upper| self.class.new(lower, upper, key: key) }
  end

  def original_spelling?(lower, upper)
    lower.spelling == pitch1.spelling && upper.spelling == pitch2.spelling
  end

  ALTERATION_SIGNS = {-2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "##"}.freeze

  def enharmonic_equivalents_for(pitch)
    equivalent_pitches = enharmonic_spellings_for(pitch.pitch_class).map do |spelling|
      HeadMusic::Rudiment::Pitch.fetch_or_create(spelling, pitch.register)
    end
    [pitch, *equivalent_pitches].uniq(&:spelling)
  end

  def enharmonic_spellings_for(target_pitch_class)
    all_spellings.select { |spelling| spelling.pitch_class == target_pitch_class }
  end

  def all_spellings
    HeadMusic::Rudiment::LetterName.all.flat_map do |letter_name|
      ALTERATION_SIGNS.each_value.map { |sign| HeadMusic::Rudiment::Spelling.get("#{letter_name}#{sign}") }
    end.compact
  end
end
