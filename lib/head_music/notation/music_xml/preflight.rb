# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Rejects compositions that cannot be expressed in the supported MusicXML
  # subset, and normalizes each bar's meter and key-signature markers in place
  # so later positional arithmetic and assembly can rely on coerced values.
  #
  # Whole-composition problems (no voices, positional gaps, barline-crossing
  # notes, forbidden control characters) raise RenderError here, before the
  # Writer assembles any output — so a successful check! is the Writer's
  # guarantee that assembly cannot fail on these grounds.
  class Preflight
    # XML 1.0 forbids the C0 control characters other than tab, newline, and
    # carriage return, even as character references.
    FORBIDDEN_TEXT_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/

    def self.check!(composition)
      new(composition).check!
    end

    def initialize(composition)
      @composition = composition
    end

    def check!
      ensure_voices
      normalize_bar_markers
      ensure_renderable_text
      ensure_contiguous_voices
      ensure_notes_within_barlines
    end

    private

    attr_reader :composition

    def ensure_voices
      return unless composition.voices.empty?

      raise RenderError, "cannot render a composition with no voices as MusicXML"
    end

    # change_meter and change_key_signature store the caller's raw value
    # (Bar's accessors are bare attr_accessors), and Position arithmetic
    # breaks on an un-coerced meter string, so markers are normalized in
    # place before any placement's next_position is computed.
    def normalize_bar_markers
      composition.bars.each do |bar|
        bar.meter = HeadMusic::Rudiment::Meter.get(bar.meter) if bar.meter
        bar.key_signature = HeadMusic::Rudiment::KeySignature.get(bar.key_signature) if bar.key_signature
      end
    end

    def ensure_renderable_text
      texts = [composition.name, composition.composer] + composition.voices.map(&:role)
      texts.compact.each do |text|
        next unless text.to_s.match?(FORBIDDEN_TEXT_CHARACTERS)

        raise RenderError, "cannot render control characters in #{text.to_s.inspect} as XML text"
      end
    end

    def ensure_contiguous_voices
      composition.voices.each do |voice|
        gap = voice.first_gap
        raise_gap_error(voice, *gap) if gap
      end
    end

    def raise_gap_error(voice, expected_position, found_placement)
      if found_placement.equal?(voice.placements.first)
        raise RenderError, "the first placement must start its bar " \
          "(found #{found_placement.position}); insert explicit rests to fill the gap"
      end

      raise RenderError, "expected a placement at #{expected_position}, " \
        "found one at #{found_placement.position}; insert explicit rests to fill gaps"
    end

    def ensure_notes_within_barlines
      composition.voices.each do |voice|
        voice.placements.each do |placement|
          next unless placement.next_position > placement.position.start_of_next_bar

          raise RenderError, "the note at #{placement.position} crosses its barline; " \
            "splitting notes across barlines is not supported"
        end
      end
    end
  end
end
