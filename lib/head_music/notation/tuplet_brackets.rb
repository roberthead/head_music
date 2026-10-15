module HeadMusic
  module Notation
    # The tuplet brackets a writer draws for a voice, one per tuplet group and
    # one per run of ungrouped values of a ratio, laid over the bar segments a
    # writer writes. A bracket holds written links, the tied pieces a writer
    # emits, so a group across a barline holds the pieces on both sides of it.
    module TupletBrackets
      # One written link: the link at an index of a segment's rhythmic value,
      # with its exact onset as [bar number, offset in the bar].
      Link = Data.define(:segment, :index, :rhythmic_value, :onset) do
        def ratio
          rhythmic_value.tuplet_ratio
        end

        def bar_number
          segment.bar_number
        end

        def written_fraction
          rhythmic_value.written_fraction
        end
      end

      Bracket = Data.define(:ratio, :unit, :links, :group) do
        def first
          links.first
        end

        def last
          links.last
        end

        def bar_numbers
          links.map(&:bar_number).uniq
        end

        def crosses_barline?
          bar_numbers.length > 1
        end

        def label
          return group.to_s if group

          "#{ratio.to_a.join(":")} tuplet at #{first.segment.voice_event.position}"
        end
      end

      module_function

      # Over the segments a writer's plan holds for the voice, or the voice's
      # own when none are given.
      def for(voice, segments = BarSplitter.segments(voice.voice_events), error_class: RenderError)
        links = written_links(segments, error_class)
        grouped = voice.tuplets.map { |group| group_bracket(group, links) }
        claimed = grouped.flat_map(&:links).to_set
        order = links.each_with_index.to_h
        (grouped + run_brackets(links, claimed)).sort_by { |bracket| order.fetch(bracket.first) }
      end

      def written_links(segments, error_class)
        segments.flat_map do |segment|
          onset = segment.offset || BarSplitter.onset_in_bar(segment.voice_event)
          segment.rhythmic_value!(error_class).tied_chain.each_with_index.map do |link, index|
            Link.new(segment, index, link, [segment.bar_number, onset]).tap { onset += link.link_fraction }
          end
        end
      end

      def group_bracket(group, links)
        from = exact_point(group.from)
        to = exact_point(group.to)
        # Links are in time order, so a group's are consecutive.
        start = links.bsearch_index { |link| (link.onset <=> from) >= 0 } || links.length
        inside = links[start..].take_while { |link| (link.onset <=> to).negative? }
        Bracket.new(group.ratio, group.unit, inside, group)
      end

      # Consecutive ungrouped links of one ratio, bracketed as a writer counts
      # them: a bracket closes once its written total reaches the ratio's
      # actual count of its shortest unit, and what is left over at the end of
      # the run forms a bracket of its own.
      def run_brackets(links, claimed)
        runs = links.chunk_while do |one, other|
          one.ratio && one.ratio == other.ratio && !claimed.include?(one) && !claimed.include?(other)
        end
        runs.select { |run| run.first.ratio && !claimed.include?(run.first) }.flat_map { |run| split_run(run) }
      end

      def split_run(run)
        ratio = run.first.ratio
        brackets = []
        current = []
        run.each do |link|
          current << link
          next if current.sum(&:written_fraction) < ratio.actual * current.map(&:written_fraction).min

          brackets << run_bracket(ratio, current)
          current = []
        end
        brackets << run_bracket(ratio, current) unless current.empty?
        brackets
      end

      def run_bracket(ratio, links)
        Bracket.new(ratio, HeadMusic::Content::TupletGroup.default_unit(links.map(&:written_fraction), ratio), links, nil)
      end

      def exact_point(position)
        [position.bar_number, BarSplitter.offset_in_bar(position)]
      end
    end
  end
end
