module HeadMusic::MIDI
  # The velocity each note event of a voice attacks with, 1..127.
  #
  # A note sounds at the level in force at its onset, or under a hairpin at a
  # velocity interpolated by its onset, then adds its note dynamic's and
  # articulations' boosts. The levels come from one forward sweep over the
  # voice's events, the part's, and the levels accents such as fp leave
  # behind, ranked as Voice#dynamic_at ranks them, so each render stays linear.
  class VelocityResolver
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

      ramp_velocity(voice_event) || velocity_of(in_force_marks.before_accent(voice_event.position))
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

    def model_marks
      @model_marks ||= LevelMarks.of(voice)
    end

    def in_force_marks
      @in_force_marks ||= model_marks.with(hairpins.follow_through)
    end

    def model_levels
      @model_levels ||= model_marks.levels(voice.voice_events)
    end

    def levels_in_force
      @levels_in_force ||= in_force_marks.levels(voice.voice_events)
    end

    def hairpins
      @hairpins ||= HairpinRamps.new(voice, model_marks)
    end

    def ramp_velocity(voice_event)
      ramp = hairpins.governing[voice_event]
      return unless ramp

      from = time_at(exact(ramp.from))
      onset = time_at(HeadMusic::Notation::BarSplitter.exact_start(voice_event))
      progress = ((onset - from) / (time_at(exact(ramp.to)) - from)).clamp(0, 1)
      from_velocity = velocity_of(ramp.start)
      (from_velocity + (velocity_of(ramp.target) - from_velocity) * progress).round
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
        ramps = hairpins.ramps
        time = 0
        (ramps.first.from.bar_number..ramps.map { |ramp| ramp.to.bar_number }.max).each_with_object({}) do |bar_number, starts|
          starts[bar_number] = time
          time += PerformanceTimeline.bar_length(flow, bar_number)
        end
      end
    end
  end
end
