require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads articulations, ornaments, and note dynamics in <notations>.
  class MarkingReader < MarkReader
  end
end
