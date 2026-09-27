# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Places the levels and accents of a \new Dynamics on the parts it governs.
  # It runs once the voices are placed, so every meter change is in force. The
  # context's own spacers say where each level falls, so it keeps its exact
  # position, even in the middle of a note.
  class PartDynamics
    def initialize(flow, layout, placer)
      @flow = flow
      @layout = layout
      @placer = placer
    end

    def place(stream)
      parts = layout.dynamics_parts(stream.dynamics_target)
      position = HeadMusic::Content::Position.new(flow, 1, 1, 0)
      stream.events.each do |event|
        placer.check_bar(event, position) if event.kind == :bar_check
        next unless event.kind == :spacer

        parts.each do |part|
          placer.place_level(part, position, event)
          place_accent(part, position, event.marks.note_dynamic)
        end
        position = after_spacer(position, event)
      end
    end

    private

    attr_reader :flow, :layout, :placer

    # A part holds no accents, so one between the staves goes on each note of
    # the part that attacks there, as kern's **dynam does. A note's own wins.
    def place_accent(part, position, note_dynamic)
      return unless note_dynamic

      part.voices.flat_map(&:note_events).each do |note_event|
        note_event.note_dynamic ||= note_dynamic if note_event.position == position
      end
    end

    def after_spacer(position, event)
      ticks = event.fraction * EventPlacer::TICKS_PER_WHOLE_NOTE
      unless ticks.denominator == 1
        raise UnsupportedFeatureError.new("A spacer of #{event.fraction} whole notes falls between ticks", line_number: event.line)
      end

      HeadMusic::Content::Position.new(flow, position.bar_number, position.count, position.tick + ticks.to_i)
    end
  end
end
