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

    def grace_velocity(voice_event, grace_note)
      clamp(base_velocity(voice_event) + articulation_boost(grace_note.articulations))
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
      @levels_in_force ||= sweep(sorted(model_marks + ramps_and_follow_through.last))
    end

    def sweep(marks)
      index = 0
      level = nil
      voice.voice_events.each_with_object({}.compare_by_identity) do |voice_event, levels|
        while index < marks.length && marks[index].position <= voice_event.position
          level = marks[index].level
          index += 1
        end
        levels[voice_event] = level
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

    def level_at(marks, position)
      index = marks.bsearch_index { |mark| mark.position > position } || marks.length
      marks[index - 1].level if index.positive?
    end

    def placed_level_at(position)
      [voice.dynamic_events, part.dynamic_events].each do |events|
        event = events.find { |candidate| candidate.position == position }
        return event.level if event
      end
      nil
    end

    def ramps
      ramps_and_follow_through.first
    end

    # Pieces are taken in order of their starts, so a piece's start level
    # sees the level an earlier piece left in force.
    def ramps_and_follow_through
      @ramps_and_follow_through ||= begin
        marks = model_marks.dup
        follow_through = []
        built = hairpin_pieces.map do |hairpin, owner_rank, piece|
          start = level_at(marks, piece.from) || default_level
          target = placed_level_at(piece.to)
          unless target
            target = beyond(start, piece.kind)
            mark = Mark.new(piece.to, FOLLOW_THROUGH_RANK, target)
            follow_through << mark
            marks = sorted(marks + [mark])
          end
          Ramp.new(hairpin, owner_rank, piece.from, piece.to, start, target)
        end
        [built, follow_through]
      end
    end

    def hairpin_pieces
      cuts = (voice.dynamic_events + part.dynamic_events).map(&:position)
      pieces = owned_hairpins.flat_map do |hairpin, owner_rank|
        HeadMusic::Notation::HairpinSegments.split([hairpin], cuts).map { |piece| [hairpin, owner_rank, piece] }
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
      ramp = governing_ramp(voice_event.position)
      return unless ramp

      onset = HeadMusic::Notation::BarSplitter.exact_start(voice_event)
      progress = (elapsed(ramp.from, onset) / elapsed(ramp.from, exact(ramp.to))).clamp(0, 1)
      from_velocity = velocity_of(ramp.start)
      (from_velocity + (velocity_of(ramp.target) - from_velocity) * progress).round
    end

    # The innermost hairpin governs, a voice's over its part's.
    def governing_ramp(position)
      covering = ramps.select { |ramp| ramp.from <= position && position < ramp.to }
      covering.min do |one, other|
        [other.hairpin.from, one.hairpin.to, other.owner_rank] <=> [one.hairpin.from, other.hairpin.to, one.owner_rank]
      end
    end

    def exact(position)
      [position.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(position)]
    end

    def elapsed(from, to)
      from_bar, from_offset = exact(from)
      to_bar, to_offset = to
      (from_bar...to_bar).sum { |bar_number| PerformanceTimeline.bar_length(flow, bar_number) } + to_offset - from_offset
    end
  end
end
