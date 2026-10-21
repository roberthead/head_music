# frozen_string_literal: true

module HeadMusic
  module Time
    # A return to the tempo in force at the start of the latest tempo ramp
    # before it. A point, so it begins and ends at its position.
    ATempo = Data.define(:position, :text)

    class ATempo
      def initialize(position:, text: "a tempo")
        super
      end

      def from
        position
      end

      def to
        position
      end
    end
  end
end
