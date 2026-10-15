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

    def instrument(document_part)
      score_part = document_part.score_part
      score_instrument = score_part && first_child(score_part, "score-instrument")
      sound = score_instrument && text(score_instrument, "instrument-sound")
      InstrumentSounds.instrument(sound)
    end

    private

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
