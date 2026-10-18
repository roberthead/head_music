# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The bars a kern file is written in: which ones, how long each is, the
  # barline before each, and every voice's tokens in each.
  #
  # A pickup bar's leading silence is left out, since kern starts a pickup
  # at its first note, unless a dynamic or hairpin mark falls in it.
  class WrittenBars
    PICKUP_BAR = 0
    STYLES = {double: "||", final: "|!"}.freeze

    def initialize(flow, plan)
      @flow = flow
      @plan = plan
    end

    def first
      plan.bar_numbers.first
    end

    def numbers
      @numbers ||= lengths.keys.reject { |bar_number| pickup?(bar_number) && pickup_start.nil? }
    end

    def length(bar_number)
      lengths.fetch(bar_number)
    end

    def pickup?(bar_number)
      bar_number == PICKUP_BAR && first == PICKUP_BAR
    end

    # Where the pickup's first note sounds, or its downbeat when a dynamic
    # comes before that note, or nil when the pickup bar holds nothing but
    # silence.
    def pickup_start
      return @pickup_start if defined?(@pickup_start)

      @pickup_start = first.zero? ? pickup_onset : nil
    end

    def events(voice, bar_number)
      events = spine_tokens(voice).fetch(bar_number)
      pickup?(bar_number) ? trimmed(events) : events
    end

    # A barline opening the first written bar is invisible unless it opens a
    # repeat; a pickup has no barline before it at all.
    def barline(bar_number)
      return if pickup?(bar_number)

      entered = plan.bar(bar_number)
      return "=#{bar_number}#{entered.starts_repeat? ? "!|:" : "-"}" if bar_number == numbers.first

      "=#{bar_number}#{barline_style(plan.bar(bar_number - 1), entered)}"
    end

    def final_barline
      "==#{":|!" if plan.bar(numbers.last).ends_repeat?}"
    end

    private

    attr_reader :flow, :plan

    # A repeat sign has lines of its own, so it takes the place of a double
    # or final barline. Kern has no dashed or dotted barline.
    def barline_style(completed, entered)
      ends = completed.ends_repeat?
      starts = entered.starts_repeat?
      return ":|!|:" if ends && starts
      return ":|!" if ends
      return "!|:" if starts

      STYLES.fetch(completed.barline, "")
    end

    def trimmed(events)
      start = pickup_start
      events.flat_map do |event|
        finish = event.finish
        next [] unless finish > start

        (event.offset < start) ? SpineTokens.rests(start, finish) : [event]
      end
    end

    def spine_tokens(voice)
      @spine_tokens ||= {}
      @spine_tokens[voice] ||= event_sources.fetch(voice).by_bar(lengths, music_end)
    end

    def event_sources
      @event_sources ||= flow.voices.to_h { |voice| [voice, SpineTokens.new(voice)] }
    end

    # Every bar's full length, except the last, which ends where the longest
    # voice does unless a dynamic follows the music in it.
    def lengths
      @lengths ||= begin
        last_bar, last_offset = music_end
        (first..last_bar).to_h do |bar_number|
          short = bar_number == last_bar && !dynamic_after_music?
          [bar_number, short ? last_offset : full_length(bar_number)]
        end
      end
    end

    # Where the longest voice stops, as [bar number, offset in that bar]. A
    # flow whose voices hold nothing is one bar of rest.
    def music_end
      @music_end ||= event_sources.values.filter_map(&:finish).max || [first, full_length(first)]
    end

    # Silence holding a tuplet rest is kept, since leaving it out would cut
    # a tuplet short.
    def pickup_onset
      events = event_sources.values.flat_map { |source| source.placed.fetch(PICKUP_BAR, []) }
      note_start = events.reject(&:rest?).map(&:offset).min
      dynamic_start = dynamic_offsets(PICKUP_BAR).min
      start = (dynamic_start.nil? || (note_start && note_start <= dynamic_start)) ? note_start : 0
      return 0 if start && events.any? { |event| event.offset < start && event.link.tuplet? }

      start
    end

    def dynamic_after_music?
      last_bar, last_offset = music_end
      dynamic_offsets(last_bar).any? { |offset| offset >= last_offset }
    end

    def dynamic_offsets(bar_number)
      mark_positions.select { |position| position.bar_number == bar_number }.map { |position| MarkOffset.in_bar(position) }
    end

    # A hairpin ending on the final barline is closed on the last row, so it
    # needs no time of its own after the music.
    def mark_positions
      owners = flow.parts + flow.voices
      hairpins = owners.flat_map(&:spans).select(&:hairpin?)
      final_barline = flow.final_barline_position
      ends = hairpins.map(&:to).reject { |position| position == final_barline }
      [*owners.flat_map(&:dynamic_events).map(&:position), *hairpins.map(&:from), *ends]
    end

    def full_length(bar_number)
      meter = plan.effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
