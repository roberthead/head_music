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
      identity = IdentityReader.new(@document)
      readings = @document.parts.map do |document_part|
        PartReader.new(document_part, instrument: identity.instrument(document_part)).read.tap do |reading|
          reading.tracks.each do |track|
            track.tie_graces
            TieFolding.apply(track, reading)
          end
        end
      end
      raise ParseError, "MusicXML input contains no music" if readings.empty?

      bar_map = BarMap.new(readings)
      timeline = TimelineReader.new(readings, bar_map)
      flow = HeadMusic::Content::Flow.new(name: identity.name, work: identity.work, composer: identity.composer, **timeline.opening)
      timeline.apply(flow)
      roster = PartRoster.new(flow, identity, bar_map)
      readings.each do |reading|
        part = roster.add(reading)
        reading.tracks.each { |track| VoicePlacer.new(part.add_voice, track, bar_map, reading).place }
      end
      flow
    end
  end
end
