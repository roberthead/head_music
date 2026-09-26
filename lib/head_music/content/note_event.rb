# A module for musical content
module HeadMusic::Content; end

# A voice event that sounds: one Soundable, or several at once as a chord.
class HeadMusic::Content::NoteEvent < HeadMusic::Content::VoiceEvent
  attr_reader :sounds

  public_class_method :new

  def initialize(voice, position, rhythmic_value, sound_or_sounds)
    super(voice, position, rhythmic_value)
    @sounds = HeadMusic::Content::SoundResolver.resolve(sound_or_sounds)
    raise ArgumentError, "a note event needs at least one sound; place a rest instead" if sounds.empty?
  end

  # Empty until sung. The MusicXML writer derives <syllabic> from these plus
  # neighboring events; melisma is the absence of a syllable here.
  def syllables
    @syllables ||= {}
  end

  # Assigns the syllable for a verse (default verse 1). Returns self so calls
  # chain across verses. Keys by the Syllable's coerced verse (not the raw
  # argument) so syllable(2) finds what sing(verse: "2") stored and mixed-type
  # keys never make syllables.keys.sort raise.
  def sing(text, verse: 1, hyphen_after: false)
    syllable = HeadMusic::Content::Syllable.new(text, verse: verse, hyphen_after: hyphen_after)
    syllables[syllable.verse] = syllable
    self
  end

  # Voice#place merges a same-position note event into the existing one, so a
  # position holds at most one event. The sound union keeps the chord free
  # of duplicates, making repeated placement of a sound idempotent. Syllables
  # are left untouched: a chord sings one syllable per verse, and the receiver
  # (the event already at this position) keeps its own.
  def merge(other)
    unless rhythmic_value == other.rhythmic_value
      raise ArgumentError,
        "cannot place a #{other.rhythmic_value} at #{position}: position occupied by a #{rhythmic_value}"
    end

    @sounds = (sounds + other.sounds).uniq.freeze
    self
  end
end
