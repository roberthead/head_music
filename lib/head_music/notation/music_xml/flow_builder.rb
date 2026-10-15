# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Builds a flow from a Document in two phases. First each part is walked
  # into exact records; then the bars are aligned across every part, the
  # timeline is applied, and only then are the voices placed, so that every
  # position is built from a known bar.
  class FlowBuilder
    def initialize(document)
      @document = document
    end

    def flow
      @flow ||= build
    end

    private

    def build
      readings = @document.parts.map { |document_part| PartReader.new(document_part).read }
      raise ParseError, "MusicXML input contains no music" if readings.empty?

      bar_map = BarMap.new(readings)
      identity = IdentityReader.new(@document)
      flow = HeadMusic::Content::Flow.new(
        name: identity.name, work: identity.work, composer: identity.composer,
        **TimelineReader.new(readings, bar_map).opening
      )
      roster = PartRoster.new(flow, identity)
      readings.each do |reading|
        part = roster.add(reading)
        reading.tracks.each { |track| VoicePlacer.new(part.add_voice, track, bar_map, reading).place }
      end
      flow
    end
  end
end
