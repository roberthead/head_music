# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes *clef interpretations. A clef outside the table is
  # dropped on import, which is safe because kern pitch does not depend
  # on the clef.
  module ClefCodes
    CLEFS_BY_CODE = {
      "G2" => "treble_clef",
      "F4" => "bass_clef",
      "Gv2" => "vocal_tenor_clef",
      "C1" => "soprano_clef",
      "C2" => "mezzo_soprano_clef",
      "C3" => "alto_clef",
      "C4" => "tenor_clef"
    }.freeze

    module_function

    def clef?(field)
      field.start_with?("*clef")
    end

    def clef(field)
      name = CLEFS_BY_CODE[field.delete_prefix("*clef")]
      name && HeadMusic::Rudiment::Clef.get(name)
    end

    def clef_field(clef)
      code = CLEFS_BY_CODE.key(clef&.name_key.to_s)
      "*clef#{code}" if code
    end
  end
end
