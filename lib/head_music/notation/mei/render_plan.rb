module HeadMusic::Notation::MEI
  # What the MEI writers need of a flow, computed before any writing: the
  # staves, the written pieces of every voice in every bar, and their ids.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    # The scale types a tonal context can have that MEI's data.MODE names.
    MODES = %w[major minor ionian dorian phrygian lydian mixolydian aeolian locrian].freeze

    attr_reader :mdiv_number

    delegate :part_number, :voice_number, :layer_voices, to: :numbering
    delegate :items, :items_of, to: :written_items

    def initialize(flow, transposed: false, mdiv_number: 1)
      @mdiv_number = mdiv_number
      super(flow, transposed: transposed)
    end

    def ids
      @ids ||= Ids.new(mdiv_number)
    end

    def staff_entries
      numbering.entries
    end

    def staff_entries_of(part)
      numbering.entries_of(part)
    end

    def staff_entry(voice, bar_number)
      numbering.entry(voice, bar_number)
    end

    def staff_number(voice, bar_number)
      staff_entry(voice, bar_number).number
    end

    def top_staff_number(part)
      staff_entries_of(part).first.number
    end

    # The one instance of an extension class for this plan, so that a class
    # registered with several hooks computes once.
    def source(source_class)
      @sources ||= {}.compare_by_identity
      @sources[source_class] ||= source_class.new(self)
    end

    def event_id(voice, position)
      ids.event(part_number(voice.part), voice_number(voice), position)
    end

    # The pitches of an item low to high, each with the id of its note.
    def note_ids(item)
      member_ids(item.voice_event.pitches, item.id)
    end

    def grace_id(item, index)
      ids.grace(item.id, index)
    end

    def grace_note_ids(grace, grace_id)
      member_ids(grace.pitches, grace_id)
    end

    def bar_length(bar_number)
      meter = effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end

    # The final bar, where the music ends before the meter does.
    def underfull?(bar_number)
      return false unless bar_number == bar_numbers.last

      flow.voices.map { |voice| written_length(voice, bar_number) }.max < bar_length(bar_number)
    end

    # The key signature event a part is written in at a bar: the sounding one,
    # or in a transposed plan the part's instrument's written key.
    def written_key_event(part, bar_number)
      event = effective_key_event(bar_number)
      transposition = transposition_at(part, bar_number)
      transposition ? transposition.key_signature_event(event) : event
    end

    # The @key.mode of the sounding key at the opening, or nil where its tonal
    # context is unknown or not one MEI names.
    def first_measure_key_mode
      key_mode(effective_key_event(bar_numbers.first))
    end

    # The @key.mode of the sounding key change at a bar, if there is one.
    def key_mode_change(bar_number)
      event = flow.key_signature_changes[bar_number]
      event && key_mode(event)
    end

    def midi_bpm(tempo)
      Decimals.format(Rational(tempo.beats_per_minute.to_s) * tempo.beat_value.fraction * 4)
    end

    def written_length(voice, bar_number)
      segments_by_bar(voice).fetch(bar_number, []).sum { |segment| WrittenItems.segment_length(segment) }
    end

    private

    def precompute_eager_data
      super
      written_items
      extension_classes.each { |source_class| source(source_class) }
    end

    def numbering
      @numbering ||= StaffNumbering.new(flow)
    end

    def written_items
      @written_items ||= WrittenItems.new(self)
    end

    def extension_classes
      [
        *EventWriter.attribute_sources, *EventWriter.child_sources,
        *MeasureWriter.attribute_sources, *MeasureWriter.control_sources,
        *SectionWriter.pre_measure_sources, SectionWriter.bar_group,
        *ScoreDefWriter.staff_def_attribute_sources
      ].compact
    end

    def member_ids(pitches, id)
      pitches = pitches.sort
      return [[pitches.first, id]] if pitches.one?

      pitches.each_with_index.map { |pitch, index| [pitch, ids.chord_member(id, index)] }
    end

    def key_value(event)
      signature = event.signature
      return "0" if signature.zero?

      signature.positive? ? "#{signature}s" : "#{-signature}f"
    end

    def key_mode(event)
      mode = event.tonal_context&.scale_type&.name.to_s
      mode if MODES.include?(mode)
    end
  end
end
