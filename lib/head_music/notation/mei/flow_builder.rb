module HeadMusic::Notation::MEI
  # Builds a flow from one Source of a Document in two phases, as the
  # MusicXML reader does. First the score is walked once into exact records:
  # each part's measures and voice tracks. Then the bars are aligned across
  # every part, the timeline is applied, and only then are the voices
  # placed, so that every position is built from a known bar. The mark
  # readers run last, once every voice is final.
  class FlowBuilder
    def initialize(source)
      @source = source
    end

    def flow
      music || raise(ParseError, "MEI input contains no music")
    end

    # The flow, or nil for a score with no music.
    def music
      @music = build unless defined?(@music)
      @music
    end

    private

    def build
      score_def = @source.editorial.children_named(@source.score, "scoreDef").first
      staff_def = score_def ? nil : @source.editorial.children_named(@source.score, "staffDef").first
      groups = StaffGroups.new(score_def, @source.editorial, score: @source.score, staff_def: staff_def)
      opening = OpeningValues.new(score_def, groups, @source.editorial)
      identity = IdentityReader.new(@source, groups)
      score = ScoreReader.new(@source, groups, opening, identity).read
      return if score.measures.empty? || score.readings.empty?

      bar_map = HeadMusic::Notation::BarMap.new(score.readings)
      fold_ties(score, bar_map)
      timeline = TimelineReader.new(score, bar_map, opening)
      flow = timeline.flow(identity)
      roster = PartRoster.new(flow, identity, groups, bar_map, @source.editorial)
      parts = {}.compare_by_identity
      voices = {}.compare_by_identity
      score.readings.each { |reading| voices.merge!(place(parts[reading] = roster.add(reading), reading, bar_map)) }
      anchors = ControlAnchors.new(flow, score, bar_map, @source, parts, voices)
      MarkReaders.run(MarkRecords.new(score, bar_map, anchors).records, flow, anchors)
      flow
    end

    def fold_ties(score, bar_map)
      score.ties.apply(score)
      HeadMusic::Notation::TieFolding.apply_to_readings(score.readings, bar_map)
    end

    # A voice's leading and trailing bars of only whole-bar rests are not
    # placed, as the writer writes a voice tacet there. Answers each track's
    # voice.
    def place(part, reading, bar_map)
      reading.keyed_tracks.each_with_object({}.compare_by_identity) do |(key, track), voices|
        voices[track] = part.add_voice(role: reading.roles[key])
        HeadMusic::Notation::VoicePlacer.new(voices[track], track, bar_map, reading, tuplet_reader: TupletReader, trim_edges: true).place
      end
    end
  end
end
