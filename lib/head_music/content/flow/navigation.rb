class HeadMusic::Content::Flow
  # The one D.C. or D.S. a performance follows: where it sits, where it goes
  # back to, and the To Coda and coda it turns on.
  class Navigation
    attr_reader :score_bars

    def initialize(score_bars)
      @score_bars = score_bars
    end

    def jump_index
      jump_indexes.first
    end

    def jump
      jump_index && score_bars[jump_index].jump
    end

    def target_index
      @target_index ||= jump.da_capo? ? 0 : segno_index
    end

    def coda_index_after(index)
      coda_index = ((index + 1)...score_bars.length).find { |candidate| score_bars[candidate].coda? }
      raise ArgumentError, "the To Coda in bar #{score_bars[index].number} has no coda sign after it" unless coda_index

      coda_index
    end

    def validate
      if jump_indexes.length > 1
        raise ArgumentError, "only one D.C. or D.S. can be followed, found them in bars #{numbers(jump_indexes)}"
      end
      return unless jump

      validate_fine if jump.to == :fine
      validate_coda if jump.to == :coda
    end

    private

    def jump_indexes
      @jump_indexes ||= score_bars.each_index.select { |index| score_bars[index].jump }
    end

    def segno_index
      index = jump_index.downto(0).find { |candidate| score_bars[candidate].segno? }
      raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no segno at or before it" unless index

      index
    end

    def validate_fine
      return if score_bars.drop(target_index).any?(&:fine?)

      raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no Fine after bar #{target_bar_number}"
    end

    def validate_coda
      to_coda_index = (target_index..jump_index).find { |index| score_bars[index].to_coda? }
      unless to_coda_index
        raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no To Coda between bar #{target_bar_number} and the jump"
      end

      coda_index_after(to_coda_index)
    end

    def jump_bar_number
      score_bars[jump_index].number
    end

    def target_bar_number
      score_bars[target_index].number
    end

    def numbers(indexes)
      indexes.map { |index| score_bars[index].number }.join(", ")
    end
  end
end
