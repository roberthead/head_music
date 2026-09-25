# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The measure-level facts the kern writer needs. Kern states the signature
  # and its interpretation separately, as *k[...] and a designation such as
  # *G:, so a key renders as both fields; the designation is nil when kern
  # has no name for the scale type or the signature carries no reading.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    KeyFields = Data.define(:signature, :designation)

    private

    def key_value(event)
      KeyFields.new(
        signature: KeyReader.signature_field(event.signature),
        designation: event.tonal_context && KeyReader.designation_field(event.tonal_context)
      )
    end
  end
end
