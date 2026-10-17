module HeadMusic
  module Notation
    # What a beam reader asks of two event records it reads in turn: whether
    # they are adjacent in a bar and both beamable, and whether a record falls
    # where the meter starts a beam group. Includers answer #beamable?.
    module BeamReading
      private

      def beamed_pair?(previous, record)
        previous && previous.bar_number == record.bar_number &&
          previous.voice_event.next_position == record.voice_event.position &&
          beamable?(previous) && beamable?(record)
      end

      def group_start?(record)
        BeamGroups.group_start?(record.onset, record.part.flow.meter_at(record.bar_number))
      end
    end
  end
end
