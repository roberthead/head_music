# A module for musical content
module HeadMusic::Content; end

# A grace note sounds before the note event that carries it and takes no time
# of its own, so it is never a voice event: positions, bars, continuity, and
# analysis pass it by. It may be slashed, as an acciaccatura, or unslashed, as
# an appoggiatura, and tied to whatever follows it.
HeadMusic::Content::GraceNote = Data.define(:sounds, :rhythmic_value, :slashed, :tied, :articulations) do
  def initialize(sounds:, rhythmic_value:, slashed: false, tied: false, articulations: [])
    super(
      sounds: resolved_sounds(sounds),
      rhythmic_value: written_value(rhythmic_value),
      slashed: slashed ? true : false,
      tied: tied ? true : false,
      articulations: resolved_articulations(articulations)
    )
  end

  alias_method :slashed?, :slashed
  alias_method :tied?, :tied

  def pitches
    sounds.select(&:pitched?)
  end

  # The pitches it ties into whatever follows it.
  def tied_pitches
    tied? ? pitches : []
  end

  def to_s
    [slashed? ? "slashed" : nil, "grace #{rhythmic_value}", sounds.join(" ")].compact.join(" ")
  end

  def to_h
    hash = {
      "sounds" => sounds.map { |sound| HeadMusic::Content::SoundResolver.datum(sound) },
      "rhythmic_value" => rhythmic_value.to_s
    }
    hash["slashed"] = true if slashed?
    hash["tied"] = true if tied?
    hash["articulations"] = articulations.map(&:name_key) unless articulations.empty?
    hash
  end

  private

  def resolved_sounds(sound_or_sounds)
    sounds = HeadMusic::Content::SoundResolver.resolve(sound_or_sounds)
    raise ArgumentError, "a grace note needs at least one sound" if sounds.empty?

    sounds
  end

  # A grace note is written as one plain or dotted value, which takes no time,
  # so a tuplet ratio means nothing.
  def written_value(identifier)
    value = HeadMusic::Rudiment::RhythmicValue.get(identifier)
    if value.nil? || value.tuplet?
      raise ArgumentError, "a grace note needs a plain or dotted value, not #{identifier.inspect}"
    end

    value
  end

  def resolved_articulations(identifiers)
    articulations = Array(identifiers).map do |identifier|
      HeadMusic::Rudiment::Articulation.get(identifier) || raise(ArgumentError, "unknown articulation: #{identifier.inspect}")
    end
    articulations.uniq(&:name_key).sort_by(&:name_key).freeze
  end
end
