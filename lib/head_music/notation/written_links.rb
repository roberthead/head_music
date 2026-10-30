module HeadMusic
  module Notation
    # The tied pieces a writer emits for bar segments, in order: one per link
    # of each segment's rhythmic value, with its exact onset as
    # [bar number, offset in the bar], a fraction of a whole note.
    module WrittenLinks
      Link = Data.define(:segment, :index, :rhythmic_value, :onset) do
        def ratio
          rhythmic_value.tuplet_ratio
        end

        def bar_number
          segment.bar_number
        end

        def offset
          onset.last
        end

        def written_fraction
          rhythmic_value.written_fraction
        end
      end

      module_function

      def for(segments, error_class: RenderError)
        segments.flat_map do |segment|
          onset = segment.offset || BarSplitter.onset_in_bar(segment.voice_event)
          segment.rhythmic_duration!(error_class).values.each_with_index.map do |link, index|
            Link.new(segment, index, link, [segment.bar_number, onset]).tap { onset += link.link_fraction }
          end
        end
      end
    end
  end
end
