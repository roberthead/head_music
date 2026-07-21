# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Computes MusicXML <beam> annotations for the ordered noteheads of one
  # measure. Pure and side-effect-free: data in, data out. The Writer builds
  # the Event list and turns the returned Beams into XML.
  class BeamGrouper
    # A single <beam number="N">type</beam> annotation.
    Beam = Struct.new(:number, :type)

    # One notehead's beaming inputs.
    # - levels: beams this notehead carries alone (eighth=1, sixteenth=2, ...);
    #   a rest or quarter-or-longer note is 0 (unbeamable).
    # - onset: integer offset from the start of the bar, in MusicXML divisions.
    # - beam_break_before: tri-state override vs. the previous event
    #   (nil = meter default, true = force break, false = force join).
    Event = Struct.new(:levels, :onset, :beam_break_before)

    def self.annotate(events, group_unit_divisions)
      new(events, group_unit_divisions).annotate
    end

    def initialize(events, group_unit_divisions)
      @events = events
      @group_unit_divisions = group_unit_divisions
    end

    def annotate
      groups.flat_map { |group| beams_for_group(group) }
    end

    private

    attr_reader :events, :group_unit_divisions

    # Phase A: segment event indices into groups of consecutive indices.
    def groups
      result = []
      events.each_index do |i|
        if i.zero? || break_before?(i)
          result << [i]
        else
          result.last << i
        end
      end
      result
    end

    def break_before?(index)
      event = events[index]
      return true if event.levels.zero?
      return true if events[index - 1].levels.zero?
      return true if event.beam_break_before == true
      return false if event.beam_break_before == false

      (event.onset % group_unit_divisions).zero?
    end

    # Phase B: emit one Array<Beam> per member, parallel to the group's events.
    def beams_for_group(group)
      return [[]] if group.size == 1

      member_beams = Array.new(group.size) { [] }
      max_level = group.map { |i| events[i].levels }.max
      (1..max_level).each { |level| add_level_beams(group, level, member_beams) }
      member_beams
    end

    def add_level_beams(group, level, member_beams)
      participating(group, level).each do |run|
        emit_run(run, level, member_beams)
      end
    end

    # Maximal runs of consecutive-within-the-group positions whose event has
    # levels >= level. Positions are indices into `group` (and member_beams).
    def participating(group, level)
      runs = []
      group.each_with_index do |event_index, position|
        if events[event_index].levels >= level
          (runs.last && runs.last.last == position - 1) ? runs.last << position : runs << [position]
        end
      end
      runs
    end

    def emit_run(run, level, member_beams)
      if run.size == 1
        position = run.first
        # A lone member at this level gets a partial beam (hook). It points
        # backward unless it is the group's first member, which has nothing
        # to hook back to.
        member_beams[position] << Beam.new(number: level, type: position.zero? ? "forward hook" : "backward hook")
        return
      end

      run.each_with_index do |position, offset|
        member_beams[position] << Beam.new(number: level, type: run_type(offset, run.size))
      end
    end

    def run_type(offset, run_size)
      return "begin" if offset.zero?
      return "end" if offset == run_size - 1

      "continue"
    end
  end
end
