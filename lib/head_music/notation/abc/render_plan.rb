# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # The measure-level facts the ABC writer needs. A key renders as the value
  # of a K: field, with the key signature its pitches are spelled in.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    KeyField = Data.define(:key_signature, :value) do
      def to_s
        value
      end
    end

    # The bars where every voice writes its part's key: wherever a part's
    # key changes, and the first bar when the parts open in different keys,
    # as a transposed score's do. Each voice then reads back in its own key,
    # since a key one voice states would otherwise spell the others.
    def key_field_bars
      @key_field_bars ||= begin
        first = bar_numbers.first
        parts = flow.voices.map(&:part).uniq
        changes = parts.flat_map { |part| measure_key_changes(part).keys } - [first]
        opening = (parts.map { |part| first_measure_key(part).to_s }.uniq.length > 1) ? [first] : []
        (opening + changes).uniq.sort
      end
    end

    private

    # A K: field names a key rather than a count of accidentals, so the
    # interpretation is written where the event has one.
    def key_value(event)
      key_signature = event.key_signature
      KeyField.new(key_signature: key_signature, value: KeyMapper.abc_value(key_signature))
    end
  end
end
