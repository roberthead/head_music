# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Adds the flow's parts, one to each part read, in document order, each
  # with its player and instrument.
  class PartRoster
    def initialize(flow, identity)
      @flow = flow
      @identity = identity
    end

    def add(reading)
      document_part = reading.document_part
      @flow.add_part(player: @identity.player(document_part), instrument: @identity.instrument(document_part))
    end
  end
end
