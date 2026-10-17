# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads a <clef>'s sign, line, and <clef-octave-change> as a catalog clef:
  # the first whose pitch has that letter, an octave change away from the
  # sign's usual register, on that line. Percussion, TAB, and clefs the
  # catalog lacks read as nil.
  module ClefReader
    module_function

    def clef(element, **where)
      sign = XmlReading.text(element, "sign", **where)
      register = AttributesWriter::CLEF_REGISTERS[sign]
      return unless register

      line = XmlReading.integer(XmlReading.text(element, "line", **where), "<line>", **where)
      octave_change = XmlReading.integer(XmlReading.text(element, "clef-octave-change", **where), "<clef-octave-change>", **where).to_i
      HeadMusic::Rudiment::Clef.placing("#{sign}#{register + octave_change}", line)
    end
  end
end
