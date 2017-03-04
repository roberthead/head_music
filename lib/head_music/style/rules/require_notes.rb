module HeadMusic
  module Style
    module Rules
      class RequireNotes
        MINIMUM_NOTES = 7

        def self.fitness(voice)
          [MINIMUM_NOTES, voice.placements.select(&:note?).length].min / MINIMUM_NOTES.to_f
        end
      end
    end
  end
end
