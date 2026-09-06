# frozen_string_literal: true

module HeadMusic
  module Time
    # A key signature change at a musical position.
    #
    # The event carries two things, because neither derives the other:
    #
    # - the *signature*, as fifths (sharps positive, flats negative), which is
    #   what is printed at the clef;
    # - optionally a *tonal context*, a Key or a Mode, which is the analytical
    #   claim about what that signature means.
    #
    # A signature underdetermines its interpretation -- two sharps is D major,
    # B minor, E dorian, or A mixolydian -- so the interpretation is optional.
    # And the interpretation does not determine the signature either, because
    # the two legitimately diverge: C dorian written in cantus mollis takes the
    # parallel minor's three flats and naturalizes the sixth, so the collection
    # is two flats while the signature is three.
    #
    # Fifths rather than a KeySignature because a KeySignature cannot be built
    # from a bare signature -- naming three flats means naming an
    # interpretation of it, after which the stored tonic and quality are wrong
    # whenever the tonal context disagrees. Fifths is also exactly what
    # MusicXML stores.
    class KeySignatureEvent
      # @return [MusicalPosition] where the change occurs
      attr_accessor :position

      # @return [Integer] fifths: sharps positive, flats negative
      attr_reader :signature

      # The interpretation of the signature: usually a Key or a Mode, and a
      # KeySignature where the scale type is one neither subclass can hold.
      #
      # @return [HeadMusic::Rudiment::DiatonicContext, HeadMusic::Rudiment::KeySignature, nil]
      attr_reader :tonal_context

      # @param position [MusicalPosition] where the change occurs
      # @param signature [Integer] fifths
      # @param tonal_context [HeadMusic::Rudiment::QualifiedDiatonicContext, nil]
      def initialize(position, signature, tonal_context: nil)
        raise ArgumentError, "signature must be an Integer number of fifths, got #{signature.inspect}" unless signature.is_a?(Integer)

        @position = position
        @signature = signature
        @tonal_context = tonal_context
      end

      # The key signature in the sense the rest of the gem means it: the
      # collection plus, where one was claimed, the tonic and scale type that
      # a style guideline needs in order to know what the first degree is.
      #
      # Falls back to the conventional reading of the signature when no
      # interpretation was given.
      #
      # @return [HeadMusic::Rudiment::KeySignature]
      def key_signature
        @key_signature ||= tonal_context ? HeadMusic::Rudiment::KeySignature.get(tonal_context.name) : printed_key_signature
      end

      # What is printed at the clef.
      #
      # The interpretation, where it agrees with the signature -- so a flow in
      # D dorian still prints as dorian, which LilyPond can say.
      #
      # Where the two diverge the signature wins, because the signature is by
      # definition what is printed. The tonic is kept if an ordinary key on it
      # prints that signature, so C dorian in cantus mollis prints as C minor
      # rather than as its relative major; failing that, the conventional
      # reading of the signature is used.
      #
      # @return [HeadMusic::Rudiment::KeySignature]
      def printed_key_signature
        @printed_key_signature ||= agreeing_interpretation || same_tonic_key || conventional_reading
      end

      # @return [Integer] the fifths a key signature prints
      def self.fifths_of(key_signature)
        key_signature.num_sharps - key_signature.num_flats
      end

      def to_s
        [signature, tonal_context].compact.join(" ")
      end

      private

      def agreeing_interpretation
        return nil if tonal_context.nil?

        key_signature if self.class.fifths_of(key_signature) == signature
      end

      # An ordinary major or minor key on the interpretation's own tonic that
      # prints this signature, which keeps the tonic the music is actually in.
      def same_tonic_key
        return nil if tonal_context.nil?

        HeadMusic::Rudiment::Key::QUALITIES.filter_map { |quality|
          candidate = HeadMusic::Rudiment::KeySignature.get("#{tonal_context.tonic_spelling} #{quality}")
          candidate if self.class.fifths_of(candidate) == signature
        }.first
      end

      def conventional_reading
        HeadMusic::Rudiment::KeySignature.get(HeadMusic::Rudiment::Key.for_fifths(signature).name)
      end
    end
  end
end
