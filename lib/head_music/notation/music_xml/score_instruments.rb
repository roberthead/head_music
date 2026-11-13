# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The <score-instrument> ids of a part: one for each instrument it plays,
  # in the order it first plays them.
  module ScoreInstruments
    module_function

    def id(part_index, instrument_index)
      "P#{part_index + 1}-I#{instrument_index + 1}"
    end

    # nil where the part plays one instrument at most, since then no note or
    # change needs to say which.
    def id_for(part, part_index, instrument)
      instruments = part.instruments
      index = instruments.index(instrument)
      id(part_index, index) if index && instruments.length > 1
    end
  end
end
