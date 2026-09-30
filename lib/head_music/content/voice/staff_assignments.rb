class HeadMusic::Content::Voice
  # Which of its part's staves a voice is written on, bar by bar.
  #
  # A crossing is one event, not a span: a left hand that rises into the
  # treble staff at bar 5 and comes back down at bar 9 is two crossings, each
  # authored where it happens. A single cross-staff note is a crossing and, a
  # bar later, another. There is no note-level special case, and nothing to
  # overlap.
  class StaffAssignments
    def initialize(part)
      @part = part
      # No stored event for the opening staff: a voice sits on its part's first
      # staff until it says otherwise, and a single-staff part needs no
      # assignments at all.
      @map = HeadMusic::Time::EventMap.new
    end

    # Never nil, because a voice always has its part's first staff.
    def staff_at(bar_number)
      @map.at(downbeat_of(bar_number)) || @part.staff_system_at(bar_number).first_staff
    end

    def assign_staff(bar_number, staff)
      ensure_staff_in_system!(staff, bar_number)
      @map.add(downbeat_of(bar_number), staff).value
    end

    def to_h
      @map.events.to_h { |event| [event.position.bar, event.value] }
    end

    # Serialized by index within the part's system at that bar, because a staff
    # has no identity of its own -- two five-line treble staves are the same
    # description of different staves.
    def to_a
      to_h.filter_map do |bar_number, staff|
        index = @part.staff_system_at(bar_number).staves.index { |candidate| candidate.equal?(staff) }
        {"number" => bar_number, "staff" => index} if index
      end
    end

    private

    # A voice may only be written on a staff its part actually has. Crossing to
    # someone else's staff is a cue, which is a layout concern, not this.
    def ensure_staff_in_system!(staff, bar_number)
      return if @part.staff_system_at(bar_number).include?(staff)

      raise ArgumentError, "the staff is not in the part's staff system at bar #{bar_number}"
    end

    def downbeat_of(bar_number)
      HeadMusic::Time::MusicalPosition.new(bar_number, HeadMusic::Time::MusicalPosition::FIRST_COUNT, 0, 0)
    end
  end
end
