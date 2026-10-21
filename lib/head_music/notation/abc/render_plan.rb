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

    private

    # A K: field names a key rather than a count of accidentals, so the
    # interpretation is written where the event has one.
    def key_value(event)
      key_signature = event.key_signature
      KeyField.new(key_signature: key_signature, value: KeyMapper.abc_value(key_signature))
    end
  end
end
