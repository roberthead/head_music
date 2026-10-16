module HeadMusic::Notation::MEI
  # The parts of a score, from the <staffGrp> tree of its opening <scoreDef>.
  # A group whose children are several <staffDef>s is one part on several
  # staves when it carries its own <label> and none of its staves does, as
  # the writer and MuseScore write a piano, or when it is braced and its
  # staves' labels are all absent or all the same, or when neither it nor
  # its staves are labeled and no measure has one layer number on two of
  # its staves, as the writer numbers a part's layers across its staves.
  # Every other staff is its own part. A part's @symbol sets its bracket,
  # and its <label> names its player. A <part> that opens with a <staffDef>
  # rather than a <scoreDef> is that one staff.
  class StaffGroups
    include XmlReading

    # The score's staff numbers in the part, in order, and the elements
    # that define it: the group of a part on several staves, if any, and a
    # <staffDef> for each staff.
    PartDefinition = Data.define(:index, :staff_numbers, :staff_defs, :group) do
      def staff_index(number)
        staff_numbers.index(number)&.+(1)
      end

      # Where the part's label and instrument are stated.
      def definers
        [group, *staff_defs.values].compact
      end
    end

    BRACKETS_BY_SYMBOL = {"brace" => :brace, "bracket" => :bracket, "bracketsq" => :bracket, "line" => :none, "none" => :none}.freeze

    attr_reader :parts

    def initialize(score_def, editorial, score: nil, staff_def: nil)
      @editorial = editorial
      @score = score
      @definitions = []
      @staff_defs = {}
      group = score_def && editorial.children_named(score_def, "staffGrp").first
      collect(group, 1) if group
      add_part([staff_def], nil) if staff_def
      @parts = @definitions.each_with_index.map do |(numbers, staff_defs, part_group), index|
        PartDefinition.new(index, numbers, staff_defs, part_group)
      end
      @parts_by_staff = @parts.flat_map { |part| part.staff_numbers.map { |number| [number, part] } }.to_h
    end

    def part_for(staff_number)
      @parts_by_staff[staff_number]
    end

    def staff_numbers
      @parts_by_staff.keys
    end

    def staff_def(number)
      @staff_defs[number]
    end

    def opening?(staff_def)
      @staff_defs.value?(staff_def)
    end

    def label(element)
      label = @editorial.children_named(element, "label").first
      text = label ? @editorial.text(label) : attribute(element, "label", element: element)
      text unless text.to_s.empty?
    end

    def bracket(part)
      return :none unless part.group

      BRACKETS_BY_SYMBOL.fetch(attribute(part.group, "symbol", element: part.group).to_s, :none)
    end

    private

    def collect(group, depth)
      raise ParseError.new("<staffGrp>s nest deeper than #{Editorial::MAX_DEPTH}", element: group) if depth > Editorial::MAX_DEPTH

      children = @editorial.children(group).select { |child| %w[staffDef staffGrp].include?(child.name) }
      return add_part(children, group) if one_part?(group, children)

      children.each { |child| (child.name == "staffDef") ? add_part([child], nil) : collect(child, depth + 1) }
    end

    def one_part?(group, children)
      return false unless children.length > 1 && children.all? { |child| child.name == "staffDef" }

      labels = children.map { |staff_def| label(staff_def) }
      return true if label(group) && labels.none?
      return true if attribute(group, "symbol", element: group) == "brace" && labels.uniq.length == 1

      !label(group) && labels.none? && layers_apart?(children)
    end

    def layers_apart?(staff_defs)
      numbers = staff_defs.map { |staff_def| AttributeValues.read(staff_def, "n", element: staff_def) }
      measure_layers.none? do |layers|
        layers.select { |pair| numbers.include?(pair.first) }.uniq.group_by(&:last).any? { |_, staves| staves.length > 1 }
      end
    end

    # For each measure, the [staff, layer] numbers of its layers.
    def measure_layers
      @measure_layers ||= [].tap do |found|
        stack = @score ? [[@score, 0]] : []
        until stack.empty?
          element, depth = stack.pop
          raise ParseError.new("<section>s nest deeper than #{Editorial::MAX_DEPTH}", element: element) if depth > Editorial::MAX_DEPTH

          children = @editorial.children(element)
          found << measure_layers_of(element, children) if element.name == "measure"
          children.reverse_each { |child| stack << [child, depth + 1] if %w[section ending measure].include?(child.name) }
        end
      end
    end

    def measure_layers_of(measure, children)
      where = {measure: attribute(measure, "n", element: measure)}
      children.select { |child| child.name == "staff" }.flat_map do |staff|
        number = AttributeValues.read(staff, "n", **where, element: staff)
        @editorial.children_named(staff, "layer").map { |layer| [number, AttributeValues.read(layer, "n", **where, staff: number, element: layer) || 1] }
      end
    end

    def add_part(staff_defs, group)
      by_number = staff_defs.to_h do |staff_def|
        number = AttributeValues.read(staff_def, "n", element: staff_def)
        raise ParseError.new("A <staffDef> has no @n", element: staff_def) unless number
        raise ParseError.new("Two <staffDef>s are numbered #{number}", element: staff_def) if @staff_defs.key?(number)

        @staff_defs[number] = staff_def
        [number, staff_def]
      end
      @definitions << [by_number.keys, by_number, group]
    end
  end
end
