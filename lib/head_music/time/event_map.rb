# frozen_string_literal: true

module HeadMusic
  module Time
    # An ordered list of (position, value) events along a timeline, answering
    # what value is in force at any position.
    #
    # Everything that changes partway through a flow is this shape -- meter,
    # tempo, key signature, instrument, staff system, clef, staff assignment --
    # so the mechanism is written once and composed into each typed map rather
    # than inherited by it. The typed maps differ in their first-event policy:
    # a meter map's first event cannot be removed, a staff-assignment map has
    # no stored first event at all and answers a default. A constructor
    # argument expresses that; a superclass would need a hook per policy.
    #
    # Values are opaque. This class never interprets one, which is why the same
    # class serves a Meter and a Clef.
    #
    # @example
    #   map = HeadMusic::Time::EventMap.new(default: "4/4")
    #   map.add(HeadMusic::Time::MusicalPosition.new(5), "3/4")
    #   map.at(HeadMusic::Time::MusicalPosition.new(7))        # => "3/4"
    #   map.change_at(HeadMusic::Time::MusicalPosition.new(7)) # => nil
    class EventMap
      # One (position, value) pair, carrying the sort tuple computed once at
      # insert so that lookups never recompute it.
      Event = Struct.new(:position, :value, :tuple) do
        # Array has no #>, so every ordering question goes through <=>.
        def after?(other_tuple)
          (tuple <=> other_tuple) > 0
        end

        def at?(other_tuple)
          tuple == other_tuple
        end

        def to_s
          "#{position}=#{value}"
        end
      end

      # @return [Object, nil] the value in force before the first event
      attr_reader :default

      # @param default [Object, nil] the value in force before the first event
      # @param removable_first_event [Boolean] whether #remove may drop the
      #   earliest event, or must preserve it as the map's opening value
      def initialize(default: nil, removable_first_event: true)
        @default = default
        @removable_first_event = removable_first_event
        @events = []
      end

      # @return [Array<Event>] the events, earliest first
      attr_reader :events

      # @return [Array<Object>] the values, earliest first
      def values
        events.map(&:value)
      end

      # @return [Boolean] true when no event has been added
      def empty?
        events.empty?
      end

      # Add or replace the event at a position.
      #
      # @return [Event] the event now at that position
      def add(position, value)
        tuple = self.class.tuple_for(position)
        index = events.index { |event| event.at?(tuple) }
        event = Event.new(position, value, tuple)
        if index
          events[index] = event
        else
          events.insert(insertion_index(tuple), event)
        end
        event
      end

      # Remove the event at a position, if there is one.
      #
      # @return [Event, nil] the removed event
      def remove(position)
        tuple = self.class.tuple_for(position)
        index = events.index { |event| event.at?(tuple) }
        return if index.nil?
        return if index.zero? && !@removable_first_event

        events.delete_at(index)
      end

      # Remove every event, except the first when the map protects it.
      #
      # @return [self]
      def clear
        @events = @removable_first_event ? [] : events.first(1)
        self
      end

      # The value in force at a position -- the most recent event at or before
      # it, or the default when there is none.
      #
      # A binary search rather than a reverse scan: every rendered note takes
      # several map lookups, and position construction itself asks for a meter
      # in a rollover loop.
      #
      # @return [Object, nil] the value in force
      def at(position)
        event_at(position)&.value || default
      end

      # The event *starting* at a position, as distinct from the one in force
      # there. A writer needs this to decide whether to print a change.
      #
      # @return [Event, nil] the event exactly at this position
      def change_at(position)
        tuple = self.class.tuple_for(position)
        events.find { |event| event.at?(tuple) }
      end

      # The most recent event at or before a position.
      #
      # @return [Event, nil]
      def event_at(position)
        tuple = self.class.tuple_for(position)
        index = events.bsearch_index { |event| event.after?(tuple) }
        index = index ? index - 1 : events.length - 1
        events[index] if index >= 0
      end

      # Yield each [start_position, end_position, value] span between two
      # positions. Positions are yielded as given -- no normalization -- so a
      # caller that needs normalized bounds normalizes them first.
      #
      # @yield [start_position, end_position, value]
      def each_segment(from_position, to_position)
        from_tuple = self.class.tuple_for(from_position)
        to_tuple = self.class.tuple_for(to_position)

        current_position = from_position
        current_value = at(from_position)

        events.each do |event|
          next unless event.after?(from_tuple)
          break unless (event.tuple <=> to_tuple) < 0

          yield current_position, event.position, current_value
          current_position = event.position
          current_value = event.value
        end

        yield current_position, to_position, current_value
      end

      # The sort key for a position. Lexical on the four components, which is
      # the ordering MusicalPosition itself uses.
      #
      # @return [Array<Integer>]
      def self.tuple_for(position)
        [position.bar, position.count, position.tick, position.subtick]
      end

      private

      def insertion_index(tuple)
        events.bsearch_index { |event| event.after?(tuple) } || events.length
      end
    end
  end
end
