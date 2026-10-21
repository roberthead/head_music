# frozen_string_literal: true

module HeadMusic
  module Time
    # A hold on every voice at once: clock time runs `stretch` times slower
    # from `from` to `to`, and no musical position moves.
    Fermata = Data.define(:from, :to, :stretch)

    class Fermata
      DEFAULT_STRETCH = 2

      def initialize(from:, to:, stretch: DEFAULT_STRETCH)
        raise ArgumentError, "a fermata ends after it begins, got #{from} to #{to}" unless (from.to_a <=> to.to_a).negative?
        raise ArgumentError, "a fermata's stretch must be a number of at least 1, got #{stretch.inspect}" unless stretch.is_a?(Numeric) && stretch >= 1

        super
      end
    end
  end
end
