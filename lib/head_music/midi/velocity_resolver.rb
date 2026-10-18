module HeadMusic::MIDI
  # The velocity each note event of a voice attacks with, 1..127.
  #
  # A note sounds at the level in force at its onset, or under a hairpin at a
  # velocity interpolated by its onset, then adds its note dynamic's and
  # articulations' boosts. The levels come from one forward sweep over the
  # voice's events, the part's, and the levels accents such as fp leave
  # behind, ranked as Voice#dynamic_at ranks them, so each render stays linear.
  #
  # A hairpin is cut wherever a level is placed inside it, and each piece
  # ramps from the level in force at its start to the level placed at its end.
  # A piece with no level at its end ramps one level beyond its start, and
  # leaves that level in force until the next one placed.
  class VelocityResolver
    Mark = Data.define(:position, :rank, :level)

    Ramp = Data.define(:hairpin, :owner_rank, :from, :to, :start, :target)

    FOLLOW_THROUGH_RANK = -1
    PART_RANK = 0
    VOICE_RANK = 1
    ACCENT_RANK = 2

    attr_reader :voice

    delegate :flow, :part, to: :voice

    def initialize(voice)
      @voice = voice
    end

    def velocity(voice_event)
      note_dynamic = voice_event.note_dynamic&.name_key
      attack = ATTACK_LEVELS[note_dynamic]
      base = attack ? VELOCITIES.fetch(attack) : base_velocity(voice_event)
      clamp(base + NOTE_DYNAMIC_BOOSTS.fetch(note_dynamic, 0) + articulation_boost(voice_event.articulations))
    end

    # A grace note sounds before its main note's note dynamic, so before the
    # level an fp leaves in force.
    def grace_velocity(voice_event, grace_note)
      clamp(grace_base_velocity(voice_event) + articulation_boost(grace_note.articulations))
    end

    # The level the model puts in force at the event's position, as
    # Voice#dynamic_at answers it, or nil where none has been written.
    def level(voice_event)
      model_levels[voice_event]
    end

    private

    def base_velocity(voice_event)
      base_velocities[voice_event] ||= ramp_velocity(voice_event) || velocity_of(levels_in_force[voice_event])
    end

    def grace_base_velocity(voice_event)
      return base_velocity(voice_event) unless voice_event.note_dynamic&.level_after

      ramp_velocity(voice_event) || velocity_of(level_before_note_dynamic(voice_event))
    end

    def level_before_note_dynamic(voice_event)
      index = in_force_marks.bsearch_index { |mark| mark.position > voice_event.position } || in_force_marks.length
      last = in_force_marks[index - 1] if index.positive?
      index -= 1 if last&.rank == ACCENT_RANK && last.position == voice_event.position
      in_force_marks[index - 1].level if index.positive?
    end

    def base_velocities
      @base_velocities ||= {}.compare_by_identity
    end

    def velocity_of(level)
      VELOCITIES.fetch(level&.name_key || DEFAULT_LEVEL)
    end

    def articulation_boost(articulations)
      articulations.sum { |articulation| ARTICULATION_BOOSTS.fetch(articulation.name_key, 0) }
    end

    def clamp(velocity)
      velocity.clamp(VELOCITY_RANGE.min, VELOCITY_RANGE.max)
    end

    def model_levels
      @model_levels ||= sweep(model_marks)
    end

    def levels_in_force
      @levels_in_force ||= sweep(in_force_marks)
    end

    def in_force_marks
      @in_force_marks ||= sorted(model_marks + ramps_and_follow_through.last)
    end

    def sweep(marks)
      cursor = ChangeCursor.new(marks, &:position)
      voice.voice_events.each_with_object({}.compare_by_identity) do |voice_event, levels|
        levels[voice_event] = cursor.at(voice_event.position)&.level
      end
    end

    def model_marks
      @model_marks ||= sorted(
        part.dynamic_events.map { |event| Mark.new(event.position, PART_RANK, event.level) } +
        voice.dynamic_events.map { |event| Mark.new(event.position, VOICE_RANK, event.level) } +
        voice.voice_events.filter_map do |voice_event|
          level_after = voice_event.note_dynamic&.level_after
          Mark.new(voice_event.position, ACCENT_RANK, level_after) if level_after
        end
      )
    end

    def sorted(marks)
      marks.each_with_index.sort_by { |mark, index| [mark.position, mark.rank, index] }.map(&:first)
    end

    def mark_at(marks, position)
      index = marks.bsearch_index { |mark| mark.position > position } || marks.length
      marks[index - 1] if index.positive?
    end

    # The first level placed at each position, the voice's over the part's.
    def placed_levels
      @placed_levels ||= (voice.dynamic_events + part.dynamic_events).each_with_object({}) do |event, levels|
        levels[event.position] = event.level unless levels.key?(event.position)
      end
    end

    def ramps
      ramps_and_follow_through.first
    end

    # Pieces are taken in order of their starts, so a piece's start level
    # sees the level an earlier piece left in force. A follow-through level
    # arrives once the starts reach it, and ranks below a level placed there.
    def ramps_and_follow_through
      @ramps_and_follow_through ||= begin
        follow_through = []
        pending = []
        arrived = nil
        built = hairpin_pieces.map do |hairpin, owner_rank, piece|
          reached, pending = pending.partition { |mark| mark.position <= piece.from }
          reached.each { |mark| arrived = mark if arrived.nil? || mark.position >= arrived.position }
          start = start_level(piece.from, arrived)
          target = placed_levels[piece.to]
          unless target
            target = beyond(start, piece.kind)
            mark = Mark.new(piece.to, FOLLOW_THROUGH_RANK, target)
            follow_through << mark
            pending << mark
          end
          Ramp.new(hairpin, owner_rank, piece.from, piece.to, start, target)
        end
        [built, follow_through]
      end
    end

    def start_level(position, arrived)
      placed = mark_at(model_marks, position)
      mark = (arrived && (placed.nil? || arrived.position > placed.position)) ? arrived : placed
      mark&.level || default_level
    end

    def hairpin_pieces
      cuts = (voice.dynamic_events + part.dynamic_events).map(&:position).uniq.sort
      pieces = owned_hairpins.flat_map do |hairpin, owner_rank|
        HeadMusic::Notation::HairpinSegments.pieces(hairpin, cuts).map { |piece| [hairpin, owner_rank, piece] }
      end
      pieces.each_with_index.sort_by { |(_, owner_rank, piece), index| [piece.from, piece.to, owner_rank, index] }.map(&:first)
    end

    def owned_hairpins
      voice.spans.select(&:hairpin?).map { |hairpin| [hairpin, VOICE_RANK] } +
        part.spans.select(&:hairpin?).map { |hairpin| [hairpin, PART_RANK] }
    end

    def default_level
      HeadMusic::Rudiment::Dynamic.get(DEFAULT_LEVEL)
    end

    def beyond(level, kind)
      levels = HeadMusic::Rudiment::Dynamic.levels
      step = (kind == :crescendo) ? 1 : -1
      levels.fetch((levels.index(level) + step).clamp(0, levels.length - 1))
    end

    def ramp_velocity(voice_event)
      ramp = governing_ramps[voice_event]
      return unless ramp

      from = time_at(exact(ramp.from))
      onset = time_at(HeadMusic::Notation::BarSplitter.exact_start(voice_event))
      progress = ((onset - from) / (time_at(exact(ramp.to)) - from)).clamp(0, 1)
      from_velocity = velocity_of(ramp.start)
      (from_velocity + (velocity_of(ramp.target) - from_velocity) * progress).round
    end

    # Ramps are in order of their starts, so one sweep beside the voice's
    # events keeps only the ramps covering each.
    def governing_ramps
      @governing_ramps ||= begin
        starts = ChangeCursor.new(ramps, &:from)
        covering = []
        voice.voice_events.each_with_object({}.compare_by_identity) do |voice_event, governing|
          position = voice_event.position
          covering.concat(starts.advance(position))
          covering.reject! { |ramp| ramp.to <= position }
          governing[voice_event] = innermost(covering)
        end
      end
    end

    # The innermost hairpin governs, a voice's over its part's.
    def innermost(covering)
      covering.min do |one, other|
        [other.hairpin.from, one.hairpin.to, other.owner_rank] <=> [one.hairpin.from, other.hairpin.to, one.owner_rank]
      end
    end

    def exact(position)
      [position.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(position)]
    end

    # A rounded onset can fall in the bar before the first ramp's.
    def time_at((bar_number, offset))
      bar_starts.fetch(bar_number) { -PerformanceTimeline.bar_length(flow, bar_number) } + offset
    end

    def bar_starts
      @bar_starts ||= begin
        time = 0
        (ramps.first.from.bar_number..ramps.map { |ramp| ramp.to.bar_number }.max).each_with_object({}) do |bar_number, starts|
          starts[bar_number] = time
          time += PerformanceTimeline.bar_length(flow, bar_number)
        end
      end
    end
  end
end
