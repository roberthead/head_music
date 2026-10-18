module HeadMusic::Notation::MEI
  # A <measure>'s children as phase one reads them: its control events,
  # every child other than its staves, and each part's layers as
  # LayerReader::Contents, their open spaces resolved. The layers are read
  # once the measure's tupletSpans are noted, since those scale the entries
  # in them.
  class MeasureContents
    attr_reader :controls

    def initialize(element, where, groups:, state:, editorial:, tuplets:)
      @where = where
      @groups = groups
      @state = state
      @editorial = editorial
      @tuplets = tuplets
      @staves = Hash.new { |hash, number| hash[number] = [] }
      @controls = []
      editorial.children(element).each { |child| (child.name == "staff") ? add_staff(child) : @controls << child }
    end

    def read(readings)
      @by_part = readings.to_h { |reading| [reading, read_part(reading)] }
      OpenSpaces.resolve(all, @state.meter)
      self
    end

    def [](reading)
      @by_part.fetch(reading)
    end

    def all
      @by_part.values.flatten
    end

    def entries
      all.flat_map(&:entries)
    end

    # The <multiRest> that fills the most bars, or nil.
    def longest_multi_rest
      entries.select { |entry| entry.kind == :multi_rest }.max_by(&:bars)
    end

    private

    def add_staff(staff)
      number = AttributeValues.read(staff, "n", **@where, element: staff) || 1
      unknown_staff(number, staff) unless @groups.part_for(number)

      @staves[number] << staff
    end

    def unknown_staff(number, element)
      if @state.added_staff?(number)
        raise UnsupportedFeatureError.new("A <staff> numbered #{number} is added by a later <staffDef>, which is not supported", **@where, element: element)
      end

      raise ParseError.new("A <staff> numbered #{number} has no <staffDef>", **@where, element: element)
    end

    def read_part(reading)
      contents = reading.definition.staff_numbers.flat_map do |number|
        @staves[number].flat_map { |staff| read_layers(staff, number, @where.merge(staff: number)) }
      end
      count_repeats(contents)
    end

    def read_layers(staff, number, where)
      @editorial.children_named(staff, "layer").map do |layer|
        default = @state.duration_default(number, AttributeValues.read(layer, "n", **where, element: layer) || 1)
        LayerReader.new(layer, @editorial, staff_number: number, tuplets: @tuplets, duration_default: default, **where).read
      end
    end

    # A layer with notes whose staff and @n an earlier layer with notes in
    # the bar shares is a voice of its own, since @n is optional.
    def count_repeats(contents)
      seen = Hash.new(0)
      contents.select(&:notes?).each do |content|
        key = [content.staff_number, content.number]
        content.occurrence = seen[key]
        seen[key] += 1
      end
      contents
    end
  end
end
