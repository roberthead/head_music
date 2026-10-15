require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads beam breaks where <beam>s differ from the default grouping.
  class BeamReader < MarkReader
  end
end
