# A module for musical content
module HeadMusic::Content; end

# A voice event that sounds: one Soundable, or several at once as a chord.
class HeadMusic::Content::NoteEvent < HeadMusic::Content::VoiceEvent
  attr_reader :sounds, :note_dynamic

  public_class_method :new

  def initialize(voice, position, rhythmic_duration, sound_or_sounds)
    super(voice, position, rhythmic_duration)
    @sounds = HeadMusic::Content::SoundResolver.resolve(sound_or_sounds)
    raise ArgumentError, "a note event needs at least one sound; place a rest instead" if sounds.empty?
  end

  # Empty until sung. The MusicXML writer derives <syllabic> from these plus
  # neighboring events.
  def syllables
    @syllables ||= {}
  end

  def extended_verses
    extension_list.sort.freeze
  end

  def extends_syllable?(verse = 1)
    extension_list.include?(verse)
  end

  # Marks this note as a held note of a melisma: it holds the verse's
  # syllable from the voice event just before it, which sings or holds that
  # verse. A verse's slot takes a syllable or an extender, never both. Returns
  # self so calls chain.
  def extend_syllable(verse: 1)
    verse = Integer(verse)
    raise ArgumentError, "the note at #{position} already sings verse #{verse}" if syllables.key?(verse)
    raise ArgumentError, "the note at #{position} has no syllable before it to hold in verse #{verse}" unless holdable?(verse)

    extension_list << verse unless extends_syllable?(verse)
    self
  end

  # Assigns the syllable for a verse (default verse 1). Returns self so calls
  # chain across verses. Keys by the Syllable's coerced verse (not the raw
  # argument) so syllable(2) finds what sing(verse: "2") stored and mixed-type
  # keys never make syllables.keys.sort raise.
  def sing(text, verse: 1, hyphen_after: false)
    syllable = HeadMusic::Content::Syllable.new(text, verse: verse, hyphen_after: hyphen_after)
    raise ArgumentError, "the note at #{position} already holds verse #{syllable.verse}" if extends_syllable?(syllable.verse)

    syllables[syllable.verse] = syllable
    self
  end

  def articulations
    sorted_markings(articulation_map)
  end

  def ornaments
    sorted_markings(ornament_map)
  end

  # Adds articulations by key, such as :staccato. A marking the event already
  # carries is ignored. Returns self so calls chain.
  def articulate(*identifiers)
    add_markings(articulation_map, HeadMusic::Rudiment::Articulation, identifiers)
  end

  def grace_notes
    grace_note_list.dup.freeze
  end

  # Adds a grace note before this event, after any it already carries.
  # Returns self so calls chain.
  def add_grace_note(sound_or_sounds, rhythmic_value, slashed: false, tied: false, articulations: [])
    add_grace_notes(HeadMusic::Content::GraceNote.new(
      sounds: sound_or_sounds, rhythmic_value: rhythmic_value, slashed: slashed, tied: tied, articulations: articulations
    ))
  end

  def add_grace_notes(*grace_notes)
    grace_note_list.concat(grace_notes)
    self
  end

  # Adds ornaments by key, such as :trill.
  def embellish(*identifiers)
    add_markings(ornament_map, HeadMusic::Rudiment::Ornament, identifiers)
  end

  # An accent that lasts this one note, such as :sfz; nil clears it. A level
  # governs the music after it, so it is placed on the voice instead.
  def note_dynamic=(identifier)
    @note_dynamic = identifier.nil? ? nil : accent_for(identifier)
  end

  # Voice#place merges a same-position event into the existing one, so a
  # position holds at most one event, and answers whichever event holds it
  # afterward. A rest placed on a note leaves it as it was. The sound union
  # keeps the chord free of duplicates, making placing a sound again
  # idempotent. Syllables, extenders, markings, and grace notes are left
  # untouched: a chord sings one syllable per verse, and the receiver (the
  # event already at this position) keeps its own.
  def merge(other)
    ensure_same_rhythmic_duration!(other)
    return self if other.rest?

    @sounds = (sounds + other.sounds).uniq.freeze
    self
  end

  private

  def holdable?(verse)
    previous = voice.voice_event_preceding(position)
    return false unless previous&.next_position == position

    !previous.syllable(verse).nil? || previous.extends_syllable?(verse)
  end

  def extension_list
    @extension_list ||= []
  end

  def grace_note_list
    @grace_note_list ||= []
  end

  def articulation_map
    @articulation_map ||= {}
  end

  def ornament_map
    @ornament_map ||= {}
  end

  def add_markings(markings, catalog, identifiers)
    identifiers.each do |identifier|
      marking = catalog.get(identifier)
      raise ArgumentError, "unknown #{catalog.name.demodulize.downcase}: #{identifier.inspect}" unless marking

      markings[marking.name_key] ||= marking
    end
    self
  end

  def sorted_markings(markings)
    markings.keys.sort.map { |key| markings[key] }.freeze
  end

  def accent_for(identifier)
    HeadMusic::Rudiment::Dynamic.fetch(identifier, kind: "accent", hint: "place it on the voice with place_dynamic")
  end
end
