module HeadMusic::Notation::MEI
  # What is in force as the walk reaches each measure: the meter and key,
  # each staff's written key and @dur.default, and the clefs and
  # instruments that a <scoreDef> or <staffDef> between measures changes
  # from the next measure on.
  #
  # The key and meter change where a later <scoreDef> states them, or
  # where the first staff's <staffDef> does in a score that states them on
  # its staves alone, as MuseScore does. A score-wide key resets every
  # staff's own. A later <scoreDef> that adds or removes staves raises.
  class StaffState
    include XmlReading

    # The clefs by staff number, and the instruments by part index, that
    # change at the next measure.
    Changes = Data.define(:clefs, :instruments)

    attr_reader :meter, :key

    def initialize(opening, groups, editorial, identity)
      @groups = groups
      @editorial = editorial
      @identity = identity
      @meter = opening.meter
      @key = opening.key
      @staff_sourced = opening.score_def.nil? ||
        (ScoreDefValues.key(opening.score_def, editorial).nil? && ScoreDefValues.meter(opening.score_def, editorial).nil?)
      @first_staff = groups.staff_numbers.first
      @written_fifths = {}
      @duration_defaults = {}
      @opening = opening
      reset_changes
      groups.staff_numbers.each { |number| read_written_key(groups.staff_def(number), number) }
    end

    def written_fifths(staff_number)
      @written_fifths.fetch(staff_number) { @key.fifths }
    end

    def duration_default(staff_number)
      @duration_defaults.fetch(staff_number) { @opening.duration_default(staff_number) }
    end

    # The changes since the last measure, which then start afresh.
    def take_changes
      Changes.new(@clefs, @instruments).tap { reset_changes }
    end

    def apply_score_def(element, **where)
      where = where.merge(element: element)
      key = ScoreDefValues.key(element, @editorial, **where)
      if key
        @key = key
        @written_fifths.clear
      end
      @meter = ScoreDefValues.meter(element, @editorial, **where) || @meter
      group = @editorial.children_named(element, "staffGrp").first
      return unless group

      staff_defs = staff_defs_in(group, 1)
      ensure_same_staves(staff_defs, element, where)
      staff_defs.each { |staff_def| apply_staff_def(staff_def, **where.except(:element)) }
    end

    def apply_staff_def(element, **where)
      number = AttributeValues.read(element, "n", **where, element: element)
      raise ParseError.new("A <staffDef> has no @n", **where, element: element) unless number
      raise ParseError.new("A <staffDef> numbered #{number} adds a staff, which is not supported", **where, element: element) unless @groups.part_for(number)

      where = where.merge(staff: number, element: element)
      read_staff_values(element, number, where)
      clef = ClefReading.staff_def_clef(element, @editorial, **where)
      @clefs[number] = clef if clef
      instr_def = @editorial.children_named(element, "instrDef").first
      instrument = instr_def && @identity.instrument_of(instr_def)
      @instruments[@groups.part_for(number).index] = instrument if instrument
    end

    private

    def reset_changes
      @clefs = {}
      @instruments = {}
    end

    def read_staff_values(element, number, where)
      default = AttributeValues.read(element, "dur.default", **where)
      @duration_defaults[number] = default if default
      if @staff_sourced && number == @first_staff
        @key = ScoreDefValues.key(element, @editorial, **where) || @key
        @meter = ScoreDefValues.meter(element, @editorial, **where) || @meter
      end
      read_written_key(element, number)
    end

    def read_written_key(staff_def, number)
      key = staff_def && ScoreDefValues.key(staff_def, @editorial, staff: number)
      @written_fifths[number] = key.fifths if key
    end

    def staff_defs_in(group, depth)
      raise ParseError.new("<staffGrp>s nest deeper than #{Editorial::MAX_DEPTH}", element: group) if depth > Editorial::MAX_DEPTH

      @editorial.children(group).flat_map do |child|
        case child.name
        when "staffDef" then [child]
        when "staffGrp" then staff_defs_in(child, depth + 1)
        else []
        end
      end
    end

    def ensure_same_staves(staff_defs, element, where)
      numbers = staff_defs.map { |staff_def| AttributeValues.read(staff_def, "n", **where, element: staff_def) }
      return if numbers.sort == @groups.staff_numbers.sort

      raise UnsupportedFeatureError.new("A <scoreDef> that adds or removes staves is not supported", **where, element: element)
    end
  end
end
