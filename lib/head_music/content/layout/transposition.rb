# A module for musical content
module HeadMusic::Content; end

class HeadMusic::Content::Layout
  # The distance between what a player reads and what the audience hears. The
  # catalog states sounding = written + sounding_transposition, so written pitch
  # is the sounding pitch moved the opposite way, applied as spelled intervals
  # rather than as Pitch + Integer, which would respell through MIDI.
  class Transposition
    # The tritone is read as an augmented fourth, the reading that keeps a
    # transposed key signature's letter names ascending.
    SIMPLE_INTERVAL_BY_SEMITONES = {
      0 => "perfect unison",
      1 => "minor second",
      2 => "major second",
      3 => "minor third",
      4 => "major third",
      5 => "perfect fourth",
      6 => "augmented fourth",
      7 => "perfect fifth",
      8 => "minor sixth",
      9 => "major sixth",
      10 => "minor seventh",
      11 => "major seventh"
    }.freeze

    # Past this a signature names no conventional key, so nothing can print it.
    MAXIMUM_FIFTHS = 7

    attr_reader :semitones, :octaves

    # The semitones are written minus sounding.
    def self.for_semitones(semitones)
      @instances ||= {}
      @instances[semitones] ||= new(semitones)
    end

    def self.for(instrument)
      for_semitones(-(instrument&.sounding_transposition || 0))
    end

    def initialize(semitones)
      @semitones = semitones.to_i
      @octaves, remainder = @semitones.divmod(12)
      @simple_interval = simple_interval_for(remainder)
    end

    private_class_method :new

    def identity?
      semitones.zero?
    end

    # What MusicXML's <transpose> calls the diatonic component.
    def diatonic_steps
      octaves * 7 + (simple_interval&.steps || 0)
    end

    # Derived from the move itself -- C major transposed -- rather than from a
    # second table that could disagree with the first.
    def fifths_delta
      @fifths_delta ||= self.class.fifths_of(key_signature("C major"))
    end

    def written(pitch)
      pitch = HeadMusic::Rudiment::Pitch.get(pitch)
      return pitch if identity?

      raise_octaves(simple_interval ? simple_interval.above(pitch) : pitch)
    end

    def sounding(pitch)
      self.class.for_semitones(-semitones).written(pitch)
    end

    def written_sound(sound)
      return sound if identity?
      return written(sound) if sound.is_a?(HeadMusic::Rudiment::Pitch)
      return written(sound).to_s if sound.is_a?(String)

      sound
    end

    # Never arithmetic on fifths, which would lose the spelling that decides how
    # the signature is printed.
    def key_signature(key_signature)
      original = HeadMusic::Rudiment::KeySignature.get(key_signature)
      return original if identity?

      written = HeadMusic::Rudiment::KeySignature.new(written_spelling(original.tonic_spelling), original.scale_type)
      ensure_printable!(written)
      written
    end

    # An interpretation this gem cannot rebuild is dropped rather than guessed
    # at, leaving the signature alone.
    def key_signature_event(event)
      return event if identity?

      written = key_signature(event.printed_key_signature)
      HeadMusic::Time::KeySignatureEvent.new(
        event.position, self.class.fifths_of(written),
        tonal_context: written_tonal_context(event.tonal_context)
      )
    end

    def to_s
      return "in concert pitch" if identity?

      "#{semitones.abs} semitones #{semitones.positive? ? "up" : "down"}"
    end

    def self.fifths_of(key_signature)
      HeadMusic::Time::KeySignatureEvent.fifths_of(key_signature)
    end

    private

    attr_reader :simple_interval

    def simple_interval_for(semitones)
      return nil if semitones.zero?

      HeadMusic::Analysis::DiatonicInterval.get(SIMPLE_INTERVAL_BY_SEMITONES.fetch(semitones))
    end

    def raise_octaves(pitch)
      octave = HeadMusic::Analysis::DiatonicInterval.get("perfect octave")
      octaves.abs.times { pitch = octaves.positive? ? octave.above(pitch) : octave.below(pitch) }
      pitch
    end

    # Registers do not spell, so a spelling moves by the simple interval alone
    # -- reached here through #written, so that the two cannot diverge.
    def written_spelling(spelling)
      written(HeadMusic::Rudiment::Pitch.get(HeadMusic::Rudiment::Spelling.get(spelling))).spelling
    end

    def written_tonal_context(context)
      return nil if context.nil?

      tonic = written_spelling(context.tonic_spelling)
      if context.respond_to?(:qualifier)
        context.class.get("#{tonic} #{context.qualifier}")
      elsif context.is_a?(HeadMusic::Rudiment::KeySignature)
        HeadMusic::Rudiment::KeySignature.new(tonic, context.scale_type)
      end
    end

    def ensure_printable!(key_signature)
      fifths = self.class.fifths_of(key_signature)
      return if fifths.abs <= MAXIMUM_FIFTHS

      enharmonic = HeadMusic::Rudiment::Key.for_fifths(fifths - (12 * (fifths.positive? ? 1 : -1)))
      raise HeadMusic::Notation::RenderError,
        "#{key_signature.name} needs #{fifths.abs} #{fifths.positive? ? "sharps" : "flats"}, " \
        "which no key signature prints; write the part in #{enharmonic.name} instead"
    end
  end
end
