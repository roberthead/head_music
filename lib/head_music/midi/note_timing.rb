module HeadMusic::MIDI
  # The pieces a note event sounds as, in exact whole notes from its onset.
  # Each piece carries the sounds it strikes and their velocity, and an +id+
  # unique within the event, which joins the parts of one piece that the
  # barlines cut.
  #
  # Grace notes sound on the beat, one piece per pitch, and the main note
  # starts after them. A shortening articulation releases early within the
  # last link of a tied chain.
  class NoteTiming
    Piece = Data.define(:sounds, :from, :to, :velocity, :id)

    LENGTH_FACTORS = {staccatissimo: Rational(1, 4), staccato: Rational(1, 2), tenuto: 1}.freeze
    PORTATO = Rational(3, 4)
    GRACE_LENGTH = Rational(1, 32)

    attr_reader :voice_event, :velocity_resolver

    def initialize(voice_event, velocity_resolver)
      @voice_event = voice_event
      @velocity_resolver = velocity_resolver
    end

    def pieces
      @pieces ||= [main_piece, *grace_pieces].compact.each_with_index.map { |piece, id| piece.with(id: id) }
    end

    def length_factor
      names = voice_event.articulations.map { |articulation| articulation.name_key.to_sym }
      return LENGTH_FACTORS[:staccatissimo] if names.include?(:staccatissimo)
      return PORTATO if names.include?(:staccato) && names.include?(:tenuto)

      names.filter_map { |name| LENGTH_FACTORS[name] }.min || 1
    end

    private

    def main_piece
      sounds = voice_event.sounds.reject { |sound| held_keys.include?(key_of(sound)) }
      Piece.new(sounds, grace_end, release, velocity_resolver.velocity(voice_event), nil) if sounds.any?
    end

    def grace_pieces
      onset = 0
      grace_notes.zip(grace_lengths).flat_map do |grace_note, length|
        from = onset
        onset += length
        grace_note.sounds.map do |sound|
          to = (grace_note.equal?(tying_grace_note) && held_keys.include?(key_of(sound))) ? release : onset
          Piece.new([sound], from, to, velocity_resolver.grace_velocity(voice_event, grace_note), nil)
        end
      end
    end

    def grace_notes
      voice_event.grace_notes
    end

    def grace_lengths
      @grace_lengths ||= begin
        lengths = uncapped_grace_lengths
        cap = fraction / 2
        (lengths.sum > cap) ? Array.new(lengths.length, cap / lengths.length) : lengths
      end
    end

    def uncapped_grace_lengths
      return [] if grace_notes.empty?
      return Array.new(grace_notes.length, GRACE_LENGTH) if grace_notes.length > 1
      return [GRACE_LENGTH] if grace_notes.first.slashed?

      [voice_event.rhythmic_value.link_fraction / 2]
    end

    def grace_end
      grace_lengths.sum(0)
    end

    # When the grace notes reach the articulated release, the main note sounds
    # that share of what they leave.
    def release
      @release ||= begin
        factor = length_factor
        articulated = fraction - (1 - factor) * voice_event.rhythmic_value.tied_chain.last.link_fraction
        (articulated > grace_end) ? articulated : grace_end + factor * (fraction - grace_end)
      end
    end

    def tying_grace_note
      grace_notes.last if grace_notes.last&.tied?
    end

    # The main note's keys that its tied last grace note holds on through it.
    def held_keys
      @held_keys ||= begin
        main_keys = voice_event.sounds.map { |sound| key_of(sound) }
        tying_grace_note ? tying_grace_note.sounds.map { |sound| key_of(sound) } & main_keys : []
      end
    end

    def key_of(sound)
      sound.pitched? ? sound.midi_note_number : sound
    end

    def fraction
      voice_event.rhythmic_value.fraction
    end
  end
end
