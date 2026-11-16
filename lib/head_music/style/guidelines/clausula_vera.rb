# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# The two-part cadence (clausula vera): the voices close on the tonic in an
# octave or unison, reached by contrary step from the second degree and the
# step below the final, sounding together just before it. Either voice may
# carry either. Salzer and Schachter require both in the next-to-last
# measure of two-part writing (p. 20).
#
# The lower approach is a half step: raised in Dorian, Mixolydian, Aeolian,
# and minor, as written in Ionian, Lydian, and major. Phrygian is the
# exception, its seventh rising a whole step while the other voice falls the
# half step from the second degree.
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
    return self.class.violation_key unless gradable? && shaped_like_clausula_vera? && !lower_approach_half_step?

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
    shaped_like_clausula_vera? && lower_approach_half_step?
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

  def lower_approach_half_step?
    rising_pair = approaches.detect { |approach, final| final.pitch > approach.pitch }
    semitones = rising_pair.last.pitch.to_i - rising_pair.first.pitch.to_i
    semitones == ((mode == :phrygian) ? 2 : 1)
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
