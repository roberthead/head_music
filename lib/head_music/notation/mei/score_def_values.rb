module HeadMusic::Notation::MEI
  # The key, meter, and tempo a <scoreDef> or <staffDef> states, by
  # attribute or by a <keySig> or <meterSig> child, MEI 4's @key.sig beside
  # MEI 5's @keysig. Each is nil where the element states none.
  module ScoreDefValues
    # A signature's fifths, with its @key.mode and @key.pname, either of
    # which may be nil.
    Key = Data.define(:fifths, :mode, :pname) do
      # A signature with no mode takes the mode whose tonic its @key.pname
      # names, else reads as its major key, as kern reads one.
      def key_signature(**where)
        scale_type = mode || mode_of_tonic || "major"
        tonal_context = HeadMusic::Notation::MusicXML::KeyMapper.tonal_context(fifths, scale_type) ||
          HeadMusic::Notation::MusicXML::KeyMapper.tonal_context(fifths, "major")
        raise UnsupportedFeatureError.new("A key of #{fifths} fifths is not supported", **where) unless tonal_context

        HeadMusic::Rudiment::KeySignature.get(tonal_context.name)
      end

      def mode_of_tonic
        return unless pname

        mapper = HeadMusic::Notation::MusicXML::KeyMapper
        mapper::TONIC_FIFTHS_BY_SCALE_TYPE.keys.find do |scale_type|
          mapper::LETTERS_BY_FIFTHS[(fifths + mapper::TONIC_FIFTHS_BY_SCALE_TYPE.fetch(scale_type) + 1) % 7] == pname
        end
      end
    end

    module_function

    def key(element, editorial, **where)
      key_sig = editorial.children_named(element, "keySig").first
      fifths = signature(element, %w[keysig key.sig], **where)
      return Key.new(fifths, value(element, "key.mode", **where), value(element, "key.pname", **where)) if fifths
      return unless key_sig

      fifths = signature(key_sig, %w[sig], **where)
      fifths && Key.new(fifths, value(key_sig, "mode", **where) || value(element, "key.mode", **where), value(key_sig, "pname", **where))
    end

    def meter(element, editorial, **where)
      meter_sig = editorial.children_named(element, "meterSig").first
      attribute_meter(element, "meter.", **where) || (meter_sig && attribute_meter(meter_sig, "", **where))
    end

    # The quarter-note tempo of a @midi.bpm.
    def tempo(element, **where)
      bpm = value(element, "midi.bpm", **where)
      bpm && HeadMusic::Rudiment::Tempo.new("quarter", number(bpm))
    end

    def attribute_meter(element, prefix, **where)
      count = value(element, "#{prefix}count", **where)
      unit = value(element, "#{prefix}unit", **where)
      return HeadMusic::Rudiment::Meter.get("#{count}/#{unit}") if count && unit

      value(element, "#{prefix}sym", **where) unless count || unit
    end

    def signature(element, names, **where)
      names.each do |name|
        fifths = value(element, name, **where)
        return fifths if fifths
      end
      nil
    end

    def value(element, name, **where)
      AttributeValues.read(element, name, **where, element: element)
    end

    def number(rational)
      (rational.denominator == 1) ? rational.to_i : rational.to_f
    end
  end
end
