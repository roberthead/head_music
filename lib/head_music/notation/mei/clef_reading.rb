module HeadMusic::Notation::MEI
  # Reads a clef, inverting ScoreDefWriter.clef_attributes: a <clef>
  # element's @shape, @line, @dis, and @dis.place, or a <staffDef>'s
  # @clef.shape and the rest. The clef is the catalog's first whose pitch has
  # the shape's letter, displaced by @dis from the letter's usual register,
  # on that line; "perc" is the neutral clef. Tablature, double treble, and
  # clefs the catalog lacks read as nil.
  module ClefReading
    module_function

    # The clef a <staffDef> states, by a <clef> child or by attributes, or
    # nil where it states none.
    def staff_def_clef(staff_def, editorial, **where)
      element = editorial.children_named(staff_def, "clef").first
      return clef(element, **where, element: element) if element
      return unless XmlReading.attribute(staff_def, "clef.shape", element: staff_def, **where)

      clef(staff_def, prefix: "clef.", **where, element: staff_def)
    end

    def clef(element, prefix: "", **where)
      shape = AttributeValues.read(element, "#{prefix}shape", **where)
      return HeadMusic::Rudiment::Clef.get("neutral_clef") if shape == "perc"

      register = ScoreDefWriter::CLEF_REGISTERS[shape]
      return unless register

      line = AttributeValues.read(element, "#{prefix}line", **where)
      octaves = AttributeValues.read(element, "#{prefix}dis", **where).to_i *
        (AttributeValues.read(element, "#{prefix}dis.place", **where) || 0)
      record = HeadMusic::Rudiment::Clef::RECORDS.find do |candidate|
        candidate[:line] == line && candidate[:pitch] == "#{shape}#{register + octaves}"
      end
      record && HeadMusic::Rudiment::Clef.get(record[:name_key])
    end
  end
end
