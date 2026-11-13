require_relative "xml_reading"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads who and what a score is, inverting the writer: the
  # <movement-title> names the flow, with the <work-title> beside it as the
  # flow's Work, and a <work-title> alone names the flow. Failing both, a
  # <credit> of type title names it, as Sibelius exports often carry the
  # title only there.
  #
  # Each composer <creator> is credited on the Work where there is one, and
  # joined into the composer string where there is none. Other creators,
  # the arranger among them, are skipped.
  class IdentityReader
    include XmlReading

    def initialize(document)
      @document = document
    end

    def name
      movement_title || work_title || credit_title
    end

    def work
      return unless movement_title && work_title

      composers.reduce(HeadMusic::Content::Work.new(title: work_title)) { |work, person| work.with_credit(person, :composer) }
    end

    def composer
      return if work

      names = composers.map(&:full_name)
      names.join(", ") unless names.empty?
    end

    # A Player with no project, as the kern reader makes.
    def player(document_part)
      name = present(text(document_part.score_part, "part-name"))
      name && HeadMusic::Content::Player.new(name: name)
    end

    # A sound may be shared, so a name wins, but only one in the sound's
    # family, since a part name such as "Soprano" may label a player.
    def instrument(document_part)
      score_part = document_part.score_part
      score_instrument = score_part && first_child(score_part, "score-instrument")
      return unless score_instrument

      sounded = InstrumentSounds.instrument(text(score_instrument, "instrument-sound"))
      named = instrument_names(score_part, score_instrument)
      found = sounded ? named.find { |instrument| same_family?(instrument, sounded) } || sounded : named.first
      found && transposed_variant(found, document_part)
    end

    private

    def instrument_names(score_part, score_instrument)
      virtual_instrument = first_child(score_instrument, "virtual-instrument")
      [
        text(score_instrument, "instrument-name"),
        text(score_part, "part-name"),
        virtual_instrument && text(virtual_instrument, "virtual-name")
      ].filter_map { |name| InstrumentNames.instrument(name) }
    end

    def same_family?(instrument, other)
      instrument.family_key && instrument.family_key == other.family_key
    end

    # "Clarinet" transposing a minor third down is the clarinet in A.
    def transposed_variant(instrument, document_part)
      semitones = first_transposition(document_part)&.semitones
      return instrument if semitones.nil? || instrument.sounding_transposition == semitones

      variants = HeadMusic::Instruments::Instrument.all.select { |variant| variant.parent_key.to_s == instrument.name_key.to_s }
      variants.find { |variant| variant.sounding_transposition == semitones } || instrument
    end

    def first_transposition(document_part)
      measure = document_part.measures.first
      attributes = measure && first_child(measure.element, "attributes")
      return unless attributes

      transpositions = AttributesReader.read(attributes, measure: measure.number, part: document_part.id).transpositions
      transpositions[nil] || transpositions[1]
    end

    def movement_title
      present(text(@document.root, "movement-title"))
    end

    def work_title
      work = @document.header("work")
      present(work && text(work, "work-title"))
    end

    def credit_title
      credit = @document.credits.find { |element| children(element, "credit-type").any? { |type| text(type) == "title" } }
      present(credit && text(credit, "credit-words"))
    end

    def composers
      @composers ||= begin
        identification = @document.header("identification")
        creators = identification ? children(identification, "creator") : []
        creators.select { |creator| attribute(creator, "type") == "composer" }
          .filter_map { |creator| present(text(creator)) }
          .map { |name| HeadMusic::Content::Person.new(full_name: name) }
      end
    end

    def present(text)
      text unless text.to_s.empty?
    end
  end
end
