module HeadMusic::MIDI
  # The lyric text a note event sings on a pass of the performance, or nil.
  #
  # For now nothing is sung.
  class LyricEvents
    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def text_for(_voice_event, _pass)
      nil
    end
  end
end
