# A module for musical instruments and their properties
module HeadMusic::Instruments; end

# Builds an instrument's localized display name from its catalog keys.
#
# The name is, in order of preference:
#   1. an explicit translation of the instrument's own key,
#   2. a name composed from the parent instrument and pitch for a child
#      instrument (e.g. "Clarinet in B♭"), or
#   3. a plain inference from the key ("bass_clarinet" -> "bass clarinet").
class HeadMusic::Instruments::InstrumentName
  # Localized name for an instrument key under the head_music.instruments scope.
  def self.translate(key, locale: "en", default: nil)
    I18n.translate(key, scope: %i[head_music instruments], locale: locale, default: default)
  end

  def initialize(name_key:, parent_key:, pitch_designation:)
    @name_key = name_key
    @parent_key = parent_key
    @pitch_designation = pitch_designation
  end

  def to_s
    self.class.translate(name_key) || child_instrument_name || inferred_name
  end

  private

  attr_reader :name_key, :parent_key, :pitch_designation

  # Name built from parent + pitch for child instruments, e.g. "Clarinet in B♭".
  def child_instrument_name
    return nil unless parent_key && pitch_designation

    "#{parent_translation} in #{format_pitch_name(pitch_designation)}"
  end

  def parent_translation
    self.class.translate(parent_key, default: parent_key.to_s.tr("_", " "))
  end

  def inferred_name
    name_key.to_s.tr("_", " ")
  end

  def format_pitch_name(pitch_designation)
    pitch_designation.to_s.tr("b", "♭").tr("#", "♯")
  end
end
