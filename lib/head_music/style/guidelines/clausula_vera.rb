# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# The two-part cadence (clausula vera): the voices close on the tonic in an
# octave or unison, reached by contrary step from the second degree and the
# step below the final, sounding together just before it. Either voice may
# carry either. Salzer and Schachter require both in the next-to-last
# measure of two-part writing (p. 20).
#
# One approach is a half step and the other a whole step, so the voices
# sound a minor third (or tenth) before the final, or a major sixth (or
# thirteenth) when the rising voice is above. The seventh is raised in
# Dorian, Mixolydian, Aeolian, and minor, and stands as written in Ionian,
# Lydian, and major. Phrygian is the exception: its seventh rises a whole
# step while the second degree falls the half step.
class HeadMusic::Style::Guidelines::ClausulaVera < HeadMusic::Style::Guideline
  FORMS = %i[clausula_vera].freeze
  UNRAISED_VIOLATION_KEY = "guidelines.clausula_vera.violations.unraised"

  def self.with(forms: FORMS, **options)
    unsupported = Array(forms) - FORMS
    if unsupported.any?
      raise ArgumentError, "ClausulaVera does not yet support the #{unsupported.join(", ")} cadence form; supported: #{FORMS.join(", ")}"
    end

    super(forms: Array(forms), **options)
  end

  def self.violation_keys(config = {})
    super + [UNRAISED_VIOLATION_KEY]
  end

  def self.template_values(config)
    super.except(:forms)
  end

  def marks
    return [] unless gradable?
    return [] if clausula_vera?

    HeadMusic::Style::Mark.for_all(cadence_notes)
  end

  # Two ways to fail: no clausula vera at all, or one whose leading tone was
  # left unraised.
  def violation_key
    return self.class.violation_key unless gradable? && shaped_like_clausula_vera? && leading_tone_unraised?

    UNRAISED_VIOLATION_KEY
  end

  private

  def companion
    cantus_firmus
  end

  def gradable?
    notes.any? && companion&.notes&.any?
  end

  def cadence_notes
    [penultimate, last_note].compact
  end

  def clausula_vera?
    shaped_like_clausula_vera? && approach_interval_contracts_by_half_step?
  end

  def shaped_like_clausula_vera?
    return @shaped if defined?(@shaped)

    @shaped = ends_on_tonic_together? && approaches_sound_together? && approaches_by_contrary_step?
  end

  def ends_on_tonic_together?
    [last_note, companion_final].all? { |note| note.spelling == tonic_spelling } &&
      last_note.position == companion_final.position
  end

  def approaches_sound_together?
    penultimate && companion_penultimate &&
      penultimate.position < companion_penultimate.next_position &&
      companion_penultimate.position < penultimate.next_position
  end

  # One voice rises by step into the final and the other falls by step from
  # the second degree.
  def approaches_by_contrary_step?
    rising, falling = approaches.partition { |approach, final| final.pitch > approach.pitch }
    return false unless rising.one? && falling.one?

    rising_pair, falling_pair = rising.first, falling.first
    [rising_pair, falling_pair].all? { |pair| HeadMusic::Analysis::MelodicInterval.new(*pair).step? } &&
      scale_degree(falling_pair.first) == 2
  end

  def approach_interval_contracts_by_half_step?
    interval = HeadMusic::Analysis::DiatonicInterval.new(rising_note.pitch, falling_note.pitch)
    if rising_note.pitch < falling_note.pitch
      interval.minor? && interval.simple_number == 3
    else
      interval.major? && interval.simple_number == 6
    end
  end

  def leading_tone_unraised?
    approach, final = rising_pair
    mode != :phrygian && final.pitch.to_i - approach.pitch.to_i == 2
  end

  def rising_pair
    approaches.detect { |approach, final| final.pitch > approach.pitch }
  end

  def rising_note
    rising_pair.first
  end

  def falling_note
    approaches.detect { |approach, final| final.pitch < approach.pitch }.first
  end

  def approaches
    [[penultimate, last_note], [companion_penultimate, companion_final]]
  end

  def penultimate
    preceding_note(last_note)
  end

  def companion_final
    companion.notes.last
  end

  def companion_penultimate
    companion.notes[-2]
  end

  def scale_degree(note)
    HeadMusic::Rudiment::ScaleDegree.new(key_signature, note.pitch.spelling).degree
  end

  def mode
    key_signature.scale_type.name
  end
end
