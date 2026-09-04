# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Everything the reader learned from a document, before any composition
  # exists: the header's identity fields and one event stream per voice.
  # The composition cannot be constructed until the opening key and meter
  # are known, and they arrive inside the first voice, so the document
  # holds the streams until the reader is done.
  class Document
    attr_accessor :title, :composer
    attr_reader :streams

    def initialize
      @streams = []
    end

    def add_stream(role = nil)
      stream = VoiceStream.new(role)
      @streams << stream
      stream
    end

    def remove_stream(stream)
      @streams.delete(stream)
    end

    def first_key_signature
      leading_event(:key)&.key_signature
    end

    def first_meter
      leading_event(:time)&.meter
    end

    private

    # The first command of a kind that precedes any music in its stream,
    # taken from the first stream that has one.
    def leading_event(kind)
      streams.each do |stream|
        event = stream.events.take_while { |candidate| !candidate.music? }.find { |candidate| candidate.kind == kind }
        return event if event
      end
      nil
    end
  end
end
