# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The key a voice spells its pitches in. A voice spells in a key it states
  # from that point on, even partway through a bar or where the flow keeps
  # another voice's key, until the flow's key changes at a later bar.
  class SpellingKey
    def initialize(voice)
      @voice = voice
    end

    def state(key_signature, bar_number)
      @stated = [key_signature, bar_number]
    end

    def at(bar_number)
      return flow.key_signature_at(bar_number) unless @stated

      key_signature, stated_bar = @stated
      changed = flow.key_signature_changes.keys.any? { |change_bar| change_bar > stated_bar && change_bar <= bar_number }
      changed ? flow.key_signature_at(bar_number) : key_signature
    end

    private

    def flow
      @voice.flow
    end
  end
end
