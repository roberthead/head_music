# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Replays a Document's voice streams onto a fresh flow, then the dynamics
  # its \new Dynamics contexts hold for their parts.
  class FlowBuilder
    # One voice's place in the replay: the events it has left, and the
    # voice they are being placed on.
    class Cursor
      attr_reader :voice

      def initialize(stream, voice)
        @events = stream.events.dup
        @voice = voice
      end

      def event
        @events.first
      end

      def done?
        @events.empty?
      end

      def advance
        @events.shift
      end

      # Key and meter changes are answered before the notes of the same
      # position, so a bar is placed under the meter that governs it.
      def sort_key
        [voice.next_position, event.music? ? 1 : 0]
      end
    end

    attr_reader :document

    def initialize(document)
      @document = document
    end

    def flow
      @flow ||= build
    end

    private

    def build
      streams = document.streams
      raise ParseError, "LilyPond input contains no music" if streams.empty?

      flow = HeadMusic::Content::Flow.new(
        name: document.title, composer: document.composer,
        key_signature: document.first_key_signature, meter: document.first_meter
      )
      layout = PartLayout.new(flow, document)
      placer = EventPlacer.new(layout)
      replay(streams.filter_map { |stream| cursor_for(layout, stream) }, placer)
      placer.finish(flow)
      part_dynamics = PartDynamics.new(flow, layout, placer)
      document.dynamics_streams.each { |stream| part_dynamics.place(stream) }
      flow
    end

    def cursor_for(layout, stream)
      voice = layout.voice_for(stream)
      voice && Cursor.new(stream, voice)
    end

    # The voices advance together rather than one after another, so a
    # \time or \key that one staff carries is in force before another
    # staff places the bar it governs. Replaying a whole voice at a time
    # would leave the earlier voices positioned under the old meter.
    def replay(cursors, placer)
      cursors = cursors.reject(&:done?)
      until cursors.empty?
        cursor = cursors.min_by(&:sort_key)
        placer.place(cursor.event, cursor.voice)
        cursor.advance
        cursors = cursors.reject(&:done?)
      end
    end
  end
end
