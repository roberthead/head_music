module HeadMusic::Notation::MEI
  # Reads who and what a score is. Its <mdiv @label> names the flow, else
  # the @label of a <music> around it, else the head's first untyped or
  # type="main" <titleStmt> title.
  #
  # A Work comes only from the head's <workList>, credited with each
  # composer its first <work> names by a <composer>, or that composer's
  # <persName> whatever its @role, or by a <persName role="composer">.
  # Without a <workList>, the <titleStmt>'s composers are joined into the
  # flow's composer.
  #
  # A part's player is the <label> of its group or its one <staffDef>, a
  # Player with no project. Its instrument is the catalog's that its
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
      element = definition.group || (definition.staff_defs.values.first if definition.staff_defs.one?)
      name = element && @groups.label(element)
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

      composers(element).reduce(HeadMusic::Content::Work.new(title: title)) do |work, name|
        work.with_credit(HeadMusic::Content::Person.new(full_name: name), :composer)
      end
    end

    def composers(element)
      return [] unless element

      @editorial.children(element).flat_map do |child|
        case child.name
        when "composer" then [composer_name(child)]
        when "respStmt" then @editorial.children_named(child, "persName").select { |person| composer_role?(person) }.map { |person| @editorial.text(person) }
        when "persName" then composer_role?(child) ? [@editorial.text(child)] : []
        else []
        end
      end.filter_map { |name| present(name) }.uniq
    end

    def composer_name(composer)
      person = @editorial.children_named(composer, "persName").first
      @editorial.text(person || composer)
    end

    def composer_role?(person)
      attribute(person, "role", element: person).to_s.strip.casecmp?("composer")
    end

    def present(text)
      text unless text.to_s.strip.empty?
    end
  end
end
