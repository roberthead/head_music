# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Places the levels, accents, and hairpins of a \new Dynamics on the parts
  # it governs. It runs once the voices are placed, so every meter change is
  # in force. The context's own spacers say where each mark falls, so it
  # keeps its exact position, even in the middle of a note, and a <> carries
  # marks to where the spacers have reached. Hairpins pair within the one
  # context, as a voice's do.
  class PartDynamics
    def initialize(flow, layout, placer)
      @flow = flow
      @layout = layout
      @placer = placer
    end

    def place(stream)
      parts = layout.dynamics_parts(stream.dynamics_target)
      hairpin_marks = EventPlacer::HairpinMarks.new
      position = HeadMusic::Content::Position.new(flow, 1, 1, 0)
      stream.events.each do |event|
        placer.check_bar(event, position) if event.kind == :bar_check
        next unless %i[spacer dynamics].include?(event.kind)

        place_dynamics(parts, position, event)
        hairpin_marks.add(position, event.marks)
        position = placer.after_spacer(position, event) if event.kind == :spacer
      end
      hairpin_marks.pair(parts, written_end: placer.written_end, final_barline: flow.final_barline_position)
    end

    private

    attr_reader :flow, :layout, :placer

    def place_dynamics(parts, position, event)
      parts.each do |part|
        placer.place_level(part, position, event)
        place_accent(part, position, event.marks.note_dynamic)
      end
    end

    # A part holds no accents, so one between the staves goes on each note of
    # the part that attacks there, as kern's **dynam does. A note's own wins.
    def place_accent(part, position, note_dynamic)
      return unless note_dynamic

      part.voices.flat_map(&:note_events).each do |note_event|
        note_event.note_dynamic ||= note_dynamic if note_event.position == position
      end
    end
  end
end
