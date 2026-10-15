require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads rehearsal marks, segno, coda, Fine, To Coda, D.C., and D.S.
  class NavigationReader < MarkReader
  end
end
