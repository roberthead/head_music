module HeadMusic::Notation::MEI
  # Reads <hairpin @form> as a crescendo or diminuendo from its start to its
  # finish, ids winning over beats, on the voice its @layer names, else on
  # its part. One with no finish is dropped, as is one its owner refuses,
  # such as one that overlaps a hairpin before it.
  class HairpinReader < MarkReader
    KINDS = {"cres" => :crescendo, "dim" => :diminuendo}.freeze

    Hairpin = Data.define(:owner, :kind, :from, :to)

    def initialize(anchors)
      super
      @hairpins = []
    end

    def control(record)
      return unless record.element.name == "hairpin" && record.span?

      kind = KINDS[XmlReading.attribute(record.element, "form", measure: record.measure, element: record.element)&.strip]
      owner = record.voice || record.part
      @hairpins << Hairpin.new(owner, kind, record.start.position, record.finish.position) if kind && owner
    end

    def apply(_flow)
      @hairpins.each { |hairpin| add(hairpin) }
    end

    private

    def add(hairpin)
      hairpin.owner.add_span(hairpin.kind, from: hairpin.from, to: hairpin.to)
    rescue ArgumentError
      nil
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::HairpinReader
