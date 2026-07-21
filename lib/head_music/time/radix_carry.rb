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
      # @return [Integer] the carry (may be negative when borrowing)
      def carry(component, radix)
        ivar = :"@#{component}"
        delta, remainder = instance_variable_get(ivar).divmod(radix)
        instance_variable_set(ivar, remainder)
        delta
      end
    end
  end
end
