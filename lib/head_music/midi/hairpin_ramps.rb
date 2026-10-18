module HeadMusic::MIDI
  # A voice's and its part's hairpins as ramps between levels. A hairpin is
  # cut wherever a level is placed inside it, and each piece ramps from the
  # level in force at its start to the level placed at its end. A piece with
  # no level at its end ramps one level beyond its start, and leaves that
  # level in force until the next one placed.
  class HairpinRamps
    Ramp = Data.define(:hairpin, :owner_rank, :from, :to, :start, :target)

    # +marks+ are the LevelMarks the model places.
    def initialize(voice, marks)
      @voice = voice
      @marks = marks
    end

    def ramps
      built.first
    end

    # The marks of the levels pieces with no level at their ends leave in force.
    def follow_through
      built.last
    end

    # {voice event => the ramp governing it}. Ramps are in order of their
    # starts, so one sweep beside the voice's events keeps only the ramps
    # covering each.
    def governing
      @governing ||= begin
        starts = ChangeCursor.new(ramps, &:from)
        covering = []
        @voice.voice_events.each_with_object({}.compare_by_identity) do |voice_event, governing|
          position = voice_event.position
          covering.concat(starts.advance(position))
          covering.reject! { |ramp| ramp.to <= position }
          governing[voice_event] = innermost(covering)
        end
      end
    end

    private

    def part
      @voice.part
    end

    # Pieces are taken in order of their starts, so a piece's start level
    # sees the level an earlier piece left in force. A follow-through level
    # arrives once the starts reach it, and ranks below a level placed there.
    def built
      @built ||= begin
        follow_through = []
        pending = []
        arrived = nil
        ramps = hairpin_pieces.map do |hairpin, owner_rank, piece|
          reached, pending = pending.partition { |mark| mark.position <= piece.from }
          reached.each { |mark| arrived = mark if arrived.nil? || mark.position >= arrived.position }
          start = start_level(piece.from, arrived)
          target = placed_levels[piece.to]
          unless target
            target = beyond(start, piece.kind)
            mark = LevelMarks::Mark.new(piece.to, LevelMarks::FOLLOW_THROUGH_RANK, target)
            follow_through << mark
            pending << mark
          end
          Ramp.new(hairpin, owner_rank, piece.from, piece.to, start, target)
        end
        [ramps, follow_through]
      end
    end

    def start_level(position, arrived)
      placed = @marks.at(position)
      mark = (arrived && (placed.nil? || arrived.position > placed.position)) ? arrived : placed
      mark&.level || HeadMusic::Rudiment::Dynamic.get(DEFAULT_LEVEL)
    end

    # The first level placed at each position, the voice's over the part's.
    def placed_levels
      @placed_levels ||= (@voice.dynamic_events + part.dynamic_events).uniq(&:position).to_h { |event| [event.position, event.level] }
    end

    def hairpin_pieces
      cuts = placed_levels.keys.sort
      pieces = owned_hairpins.flat_map do |hairpin, owner_rank|
        HeadMusic::Notation::HairpinSegments.pieces(hairpin, cuts).map { |piece| [hairpin, owner_rank, piece] }
      end
      pieces.each_with_index.sort_by { |(_, owner_rank, piece), index| [piece.from, piece.to, owner_rank, index] }.map(&:first)
    end

    def owned_hairpins
      [[@voice, LevelMarks::VOICE_RANK], [part, LevelMarks::PART_RANK]].flat_map do |owner, rank|
        owner.spans.select(&:hairpin?).map { |hairpin| [hairpin, rank] }
      end
    end

    def beyond(level, kind)
      levels = HeadMusic::Rudiment::Dynamic.levels
      step = (kind == :crescendo) ? 1 : -1
      levels.fetch((levels.index(level) + step).clamp(0, levels.length - 1))
    end

    # The innermost hairpin governs, a voice's over its part's.
    def innermost(covering)
      covering.min do |one, other|
        [other.hairpin.from, one.hairpin.to, other.owner_rank] <=> [one.hairpin.from, other.hairpin.to, one.owner_rank]
      end
    end
  end
end
