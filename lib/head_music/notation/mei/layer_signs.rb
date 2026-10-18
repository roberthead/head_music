module HeadMusic::Notation::MEI
  # The clefs and key a <layer> states around its entries: a <clef> before
  # the first entry opens the layer, and one after the last closes it, as
  # MuseScore writes a change at the end of the bar before it; one in
  # between is skipped. A <keySig> before the first entry opens the layer,
  # and one after it raises, since skipping it would misspell what follows.
  class LayerSigns
    attr_reader :opening_clef, :opening_key

    def initialize(**where)
      @where = where
    end

    def clef(element, entry_count)
      return @last_clef = [element, entry_count] if entry_count.positive?

      @opening_clef ||= read_clef(element)
    end

    def key_sig(element, entry_count)
      raise UnsupportedFeatureError.new("A <keySig> after the first event of a <layer> is not supported", **@where, element: element) if entry_count.positive?

      @opening_key ||= ScoreDefValues.key_sig(element, **@where)
    end

    def closing_clef(entry_count)
      element, count = @last_clef
      read_clef(element) if element && count == entry_count
    end

    private

    def read_clef(element)
      ClefReading.clef(element, **@where, element: element)
    end
  end
end
