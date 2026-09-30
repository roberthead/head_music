class HeadMusic::Content::Flow
  # The bars in the order they are played: repeats unfolded, each ending on its
  # pass, and a D.C. or D.S. followed to its Fine or coda. After the jump no
  # repeat is taken again, and each repeated section plays its last ending.
  class PerformanceOrder
    # pass: the repeat pass, which endings and verses key on.
    # playing: how many times this bar has sounded, counting this one.
    PlayedBar = Data.define(:bar, :pass, :playing) do
      def number
        bar.number
      end
    end

    Region = Data.define(:start, :final_pass)

    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def bars
      validate_navigation
      walk
    end

    private

    def score_bars
      @score_bars ||= flow.bars(last_number)
    end

    def last_number
      [flow.latest_bar_number, flow.last_marked_bar_number].compact.max
    end

    # A region opens at the first bar and at each repeat start. Once a repeat
    # has ended in it, the region runs on through its endings and closes at
    # the first bar outside them, so a closing repeat with no opening repeat
    # goes back to the bar after the last section.
    def region_starts
      @region_starts ||= begin
        start = nil
        repeat_ended = false
        score_bars.each_with_index.map do |bar, index|
          if start.nil? || bar.starts_repeat? || (repeat_ended && bar.plays_on_passes.nil?)
            start = index
            repeat_ended = false
          end
          repeat_ended ||= bar.ends_repeat?
          start
        end
      end
    end

    def regions
      @regions ||= region_starts.uniq.to_h { |start| [start, Region.new(start, final_pass_from(start))] }
    end

    def region_at(index)
      regions[region_starts[index]]
    end

    def final_pass_from(start)
      members = score_bars.select.with_index { |_bar, index| region_starts[index] == start }
      [1, *members.filter_map(&:ends_repeat_after_num_plays), *members.flat_map { |bar| bar.plays_on_passes || [] }].max
    end

    def jump_indexes
      @jump_indexes ||= score_bars.each_index.select { |index| score_bars[index].jump }
    end

    def jump_index
      jump_indexes.first
    end

    def jump
      jump_index && score_bars[jump_index].jump
    end

    def validate_navigation
      if jump_indexes.length > 1
        raise ArgumentError, "only one D.C. or D.S. can be followed, found them in bars #{numbers(jump_indexes)}"
      end
      return unless jump

      validate_fine if jump.to == :fine
      validate_coda if jump.to == :coda
    end

    def target_index
      @target_index ||= jump.da_capo? ? 0 : segno_index
    end

    def segno_index
      index = (0..jump_index).to_a.reverse.find { |candidate| score_bars[candidate].segno? }
      raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no segno at or before it" unless index

      index
    end

    def validate_fine
      return if (target_index...score_bars.length).any? { |index| score_bars[index].fine? }

      raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no Fine after bar #{score_bars[target_index].number}"
    end

    def validate_coda
      to_coda_index = (target_index..jump_index).find { |index| score_bars[index].to_coda? }
      unless to_coda_index
        raise ArgumentError, "the #{jump} in bar #{jump_bar_number} has no To Coda between bar #{score_bars[target_index].number} and the jump"
      end

      coda_index_after(to_coda_index)
    end

    def coda_index_after(index)
      coda_index = ((index + 1)...score_bars.length).find { |candidate| score_bars[candidate].coda? }
      raise ArgumentError, "the To Coda in bar #{score_bars[index].number} has no coda sign after it" unless coda_index

      coda_index
    end

    def jump_bar_number
      score_bars[jump_index].number
    end

    def numbers(indexes)
      indexes.map { |index| score_bars[index].number }.join(", ")
    end

    def walk
      @played = []
      @playings = Hash.new(0)
      @after_jump = false
      @coda_taken = false
      index = 0
      region = region_at(0)
      pass = 1
      while index < score_bars.length
        unless region_at(index) == region
          region = region_at(index)
          pass = @after_jump ? region.final_pass : 1
        end
        bar = score_bars[index]
        unless bar.plays_on_pass?(pass)
          index += 1
          next
        end

        play(bar, pass)
        break if stops_at?(bar)

        if goes_to_coda?(bar)
          @coda_taken = true
          index = coda_index_after(index)
        elsif bar.ends_repeat? && !@after_jump && pass < region.final_pass
          pass += 1
          index = region.start
        elsif index == jump_index && !@after_jump
          @after_jump = true
          index = target_index
          region = region_at(index)
          pass = region.final_pass
        else
          index += 1
        end
      end
      @played
    end

    def play(bar, pass)
      @playings[bar.number] += 1
      @played << PlayedBar.new(bar: bar, pass: pass, playing: @playings[bar.number])
    end

    def stops_at?(bar)
      @after_jump && bar.fine? && jump.to != :coda
    end

    def goes_to_coda?(bar)
      @after_jump && !@coda_taken && bar.to_coda? && jump.to != :fine
    end
  end
end
