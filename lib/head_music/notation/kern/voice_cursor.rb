# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One live kern track's place in the file: the layer its tokens go to,
  # and when the note it last attacked stops sounding.
  class VoiceCursor
    attr_reader :layer
    attr_accessor :busy_until

    def initialize(layer, busy_until)
      @layer = layer
      @busy_until = busy_until
    end

    def read(token, time)
      layer.add(time, token)
      @busy_until = time + token.fraction
    end
  end
end
