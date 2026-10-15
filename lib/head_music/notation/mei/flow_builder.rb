module HeadMusic::Notation::MEI
  # Builds a flow from one Source of a Document in two phases, as the
  # MusicXML reader does. First the score is walked once into exact records:
  # each part's measures and voice tracks. Then the bars are aligned across
  # every part, the timeline is applied, and only then are the voices
  # placed, so that every position is built from a known bar.
  class FlowBuilder
    def initialize(source)
      @source = source
    end

    def flow
      @flow ||= build
    end

    private

    def build
      score_def = @source.editorial.children_named(@source.score, "scoreDef").first
      groups = StaffGroups.new(score_def, @source.editorial)
      opening = OpeningValues.new(score_def, groups, @source.editorial)
      identity = IdentityReader.new(@source, groups)
      score = ScoreReader.new(@source, groups, opening, identity).read
      raise ParseError, "MEI input contains no music" if score.measures.empty? || score.readings.empty?

      bar_map = HeadMusic::Notation::BarMap.new(score.readings)
      fold_ties(score.readings, bar_map)
      timeline = TimelineReader.new(score, bar_map, opening)
      flow = HeadMusic::Content::Flow.new(name: identity.name, work: identity.work, composer: identity.composer, **timeline.opening)
      timeline.apply(flow)
      roster = PartRoster.new(flow, identity, groups, bar_map, @source.editorial)
      score.readings.each { |reading| place(roster.add(reading), reading, bar_map) }
      flow
    end

    def fold_ties(readings, bar_map)
      readings.each do |reading|
        reading.tracks.each do |track|
          track.tie_graces
          HeadMusic::Notation::TieFolding.apply(track, reading, bar_map)
        end
      end
    end

    def place(part, reading, bar_map)
      reading.tracks.each do |track|
        voice = part.add_voice
        HeadMusic::Notation::VoicePlacer.new(voice, track, bar_map, reading, tuplet_reader: TupletReader).place
      end
    end
  end
end
