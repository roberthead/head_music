# A module for musical content
module HeadMusic::Content; end

# Resolves the raw sound argument(s) passed to Placement.new into a frozen,
# de-duplicated array of sound objects. Each value may be a Pitch, an
# UnpitchedSound, an Instrument (resolved to its percussive hit), or a name
# resolvable to one of those; an unresolvable name raises with guidance.
class HeadMusic::Content::SoundResolver
  def self.resolve(sound_or_sounds)
    new.resolve(sound_or_sounds)
  end

  def resolve(sound_or_sounds)
    return [].freeze if sound_or_sounds.nil?

    values = sound_or_sounds.is_a?(Array) ? sound_or_sounds : [sound_or_sounds]
    values.map { |value| resolve_sound(value) }.uniq.freeze
  end

  private

  def resolve_sound(value)
    return value if value.is_a?(HeadMusic::Rudiment::UnpitchedSound)
    return HeadMusic::Rudiment::UnpitchedSound.get(value) if value.is_a?(HeadMusic::Instruments::Instrument)

    pitch = HeadMusic::Rudiment::Pitch.get(value)
    return pitch if pitch

    unpitched_sound(value) || raise(ArgumentError, unknown_sound_message(value))
  end

  # A bare name resolves to a percussive hit only on an unpitched instrument;
  # naming a pitched instrument is ambiguous, so it raises instead.
  # UnpitchedSound.get(nil) is the generic sound, so nil is excluded here to
  # preserve nil-as-rest at the argument level and nil-raises inside arrays.
  def unpitched_sound(value)
    return nil if value.nil?

    sound = HeadMusic::Rudiment::UnpitchedSound.get(value)
    return nil unless sound&.instrument
    return nil if sound.instrument.pitched?

    sound
  end

  def unknown_sound_message(value)
    if HeadMusic::Instruments::Instrument.get(value)&.pitched?
      "#{value.inspect} is a pitched instrument; place a pitch such as \"D4\", " \
        "or pass HeadMusic::Rudiment::UnpitchedSound.get(#{value.inspect}) for a percussive hit"
    else
      "unknown sound: #{value.inspect}"
    end
  end
end
