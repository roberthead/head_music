# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Builds a flow from a Document in two phases. First each part is walked
  # into exact records; then the bars are aligned across every part, the
  # timeline is applied, and only then are the voices placed, so that every
  # position is built from a known bar. The mark readers run last, once
  # every voice is final.
  class FlowBuilder
    def initialize(document)
      @document = document
    end

    def flow
      @flow ||= build
    end

    private

    def build
      identity = IdentityReader.new(@document)
      readings = @document.parts.map do |document_part|
        PartReader.new(document_part, instrument: identity.instrument(document_part)).read
      end
      raise ParseError, "MusicXML input contains no music" if readings.empty?

      bar_map = HeadMusic::Notation::BarMap.new(readings)
      HeadMusic::Notation::TieFolding.apply_to_readings(readings, bar_map)
      timeline = TimelineReader.new(readings, bar_map)
      flow = timeline.flow(identity)
      roster = PartRoster.new(flow, identity, bar_map)
      records = readings.flat_map { |reading| place(roster.add(reading), reading, bar_map) }
      MarkReaders.run(records, flow)
      flow
    end

    # Answers the part's mark records, once its voices are final.
    def place(part, reading, bar_map)
      voices = reading.tracks.to_h do |track|
        voice = part.add_voice
        HeadMusic::Notation::VoicePlacer.new(voice, track, bar_map, reading, tuplet_reader: TupletReader).place
        [track.label, voice]
      end
      MarkRecords.new(part, reading, bar_map, voices).records
    end
  end
end
