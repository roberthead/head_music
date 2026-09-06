# frozen_string_literal: true

module HeadMusic
  module Time
    # Shared helper for positional/timecode components that carry between
    # radix-bounded fields (e.g. bars:beats:ticks, hours:minutes:seconds:frames).
    module RadixCarry
      private

      # Divide the named component by its radix, store the remainder back,
      # and return the amount to carry into the next-higher component.
      #
      # A 1-indexed component (a beat, whose values run 1..radix) is shifted
      # into 0-indexed space before the divmod and back afterward, so that the
      # last value in the range stays put instead of carrying.
      #
      # @param first [Integer] the component's lowest valid value
      # @return [Integer] the carry (may be negative when borrowing)
      def carry(component, radix, first: 0)
        ivar = :"@#{component}"
        delta, remainder = (instance_variable_get(ivar) - first).divmod(radix)
        instance_variable_set(ivar, remainder + first)
        delta
      end
    end
  end
end
