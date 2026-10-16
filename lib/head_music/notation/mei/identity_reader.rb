module HeadMusic::Notation::MEI
  # Reads who and what a score is. Its <mdiv @label> names the flow, else
  # the @label of a <music> around it, else the head's first untyped or
  # type="main" <titleStmt> title.
  #
  # A Work comes only from the head's <workList>, credited with each
  # composer its first <work> names by a <composer>, or that composer's
  # <persName> whatever its @role, or by a <persName role="composer">. Its
  # catalog number is an <identifier>, and its year the date of its
  # <creation>.
  # Without a <workList>, the <titleStmt>'s composers are joined into the
  # flow's composer.
  #
  # A part's player is the <label> of its group, else the one its staves
  # all share, a Player with no project. Its instrument is the catalog's that its
  # <instrDef @label> names, else the one GM_PROGRAMS gives for its
  # @midi.instrnum, numbered from 0.
  class IdentityReader
    include XmlReading

    # Name keys by General MIDI program, numbered from 1. Where several
    # instruments share a program, the commonest stands for it; the choir
    # program names no one voice, so it is left out.
    GM_PROGRAMS = {
      1 => "piano", 7 => "harpsichord", 8 => "clavichord", 9 => "celesta", 10 => "glockenspiel", 12 => "vibraphone",
      13 => "marimba", 14 => "xylophone", 15 => "chimes", 16 => "hammered_dulcimer", 20 => "organ", 22 => "accordion",
      23 => "harmonica", 25 => "guitar", 26 => "mandolin", 34 => "bass_guitar", 41 => "violin", 42 => "viola",
      43 => "cello", 44 => "double_bass", 47 => "harp", 48 => "timpani", 57 => "trumpet", 58 => "trombone",
      59 => "tuba", 61 => "french_horn", 65 => "soprano_saxophone", 66 => "alto_saxophone", 67 => "tenor_saxophone",
      68 => "baritone_saxophone", 69 => "oboe", 70 => "cor_anglais", 71 => "bassoon", 72 => "clarinet",
      73 => "piccolo_flute", 74 => "flute", 75 => "alto_recorder", 105 => "sitar", 106 => "banjo",
      110 => "great_highland_bagpipe"
    }.freeze

    NAME_KEY = /\A[A-Za-z0-9_ .-]{1,64}\z/
    # The <identifier> types a catalog number is taken from, in preference.
    CATALOG_TYPES = ["catalog", "work", nil, "opus"].freeze

    def initialize(source, groups)
      @source = source
      @groups = groups
      @editorial = source.editorial
    end

    def name
      present(attribute(@source.mdiv, "label", element: @source.mdiv)) || @source.labels.first || head_title
    end

    def work
      return @work if defined?(@work)

      @work = work_element && build_work(work_element)
    end

    def composer
      return if work_list

      names = composers(title_statement)
      names.join(", ") unless names.empty?
    end

    def player(definition)
      labels = definition.staff_defs.values.map { |staff_def| @groups.label(staff_def) }.uniq
      name = (definition.group && @groups.label(definition.group)) || (labels.first if labels.one?)
      name && HeadMusic::Content::Player.new(name: name)
    end

    def instrument(definition)
      definition.definers.each do |definer|
        instr_def = @editorial.children_named(definer, "instrDef").first
        found = instr_def && instrument_of(instr_def)
        return found if found
      end
      nil
    end

    def instrument_of(instr_def)
      label = attribute(instr_def, "label", element: instr_def)
      named = label&.match?(NAME_KEY) && HeadMusic::Instruments::Instrument.get(label)
      return named if named

      program = AttributeValues.read(instr_def, "midi.instrnum", element: instr_def)
      name_key = program && GM_PROGRAMS[program + 1]
      name_key && HeadMusic::Instruments::Instrument.get(name_key)
    end

    private

    def head
      @source.head
    end

    def title_statement
      file_desc = head && first_child(head, "fileDesc")
      file_desc && first_child(file_desc, "titleStmt")
    end

    def work_list
      head && first_child(head, "workList")
    end

    def work_element
      work_list && @editorial.children_named(work_list, "work").first
    end

    def head_title
      title_of(title_statement)
    end

    # The first untyped or main title's text, without the subordinate,
    # uniform, or other typed <titlePart>s within it.
    def title_of(element)
      return unless element

      title = @editorial.children_named(element, "title").find { |candidate| main?(candidate) }
      present(title && @editorial.text(title, skip: ->(part) { part.name == "titlePart" && !main?(part) }))
    end

    def main?(element)
      [nil, "main"].include?(attribute(element, "type", element: element))
    end

    def build_work(element)
      title = title_of(element)
      return unless title

      work = HeadMusic::Content::Work.new(title: title, catalog_number: catalog_number(element), year: creation_year(element))
      people(element).reduce(work) { |credited, person| credited.with_credit(person, :composer) }
    end

    def composers(element)
      composer_names(element).filter_map { |name| present(@editorial.text(name)) }.uniq
    end

    def people(element)
      composer_names(element).filter_map { |name| person(name) }.uniq(&:full_name)
    end

    # The elements that name a composer: a <composer>'s <persName>, else the
    # <composer> itself, and each <persName role="composer">.
    def composer_names(element)
      return [] unless element

      @editorial.children(element).flat_map do |child|
        case child.name
        when "composer" then [@editorial.children_named(child, "persName").first || child]
        when "respStmt" then @editorial.children_named(child, "persName").select { |person| composer_role?(person) }
        when "persName" then composer_role?(child) ? [child] : []
        else []
        end
      end
    end

    # A person's life is the dates of their name, and their sort name its
    # family name and forenames, where it has both.
    def person(element)
      full_name = present(@editorial.text(element))
      return unless full_name

      birth, death = %w[startdate enddate].map { |name| AttributeValues.read(element, name, element: element) }
      birth = death = nil if birth && death && death < birth
      HeadMusic::Content::Person.new(full_name: full_name, sort_name: sort_name(element), birth_year: birth, death_year: death)
    end

    def sort_name(element)
      family, given = %w[famName foreName].map do |name|
        part = @editorial.children_named(element, name).first
        part && present(@editorial.text(part))
      end
      "#{family}, #{given}" if family && given
    end

    def catalog_number(element)
      identifiers = @editorial.children_named(element, "identifier")
      CATALOG_TYPES.each do |type|
        found = identifiers.find { |identifier| attribute(identifier, "type", element: identifier) == type }
        text = found && present(@editorial.text(found))
        return text if text
      end
      nil
    end

    def creation_year(element)
      creation = @editorial.children_named(element, "creation").first
      date = creation && @editorial.children_named(creation, "date").first
      return unless date

      AttributeValues.read(date, "isodate", element: date) || AttributeValues.parse("isodate", @editorial.text(date))
    end

    def composer_role?(person)
      attribute(person, "role", element: person).to_s.strip.casecmp?("composer")
    end

    def present(text)
      text unless text.to_s.strip.empty?
    end
  end
end
