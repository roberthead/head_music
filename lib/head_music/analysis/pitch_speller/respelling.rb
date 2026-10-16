class HeadMusic::Analysis::PitchSpeller
  # Respells a flow's pitched sounds, grace notes included, into a new flow
  # built through to_h and Flow.from_h, so the flow given is left alone and the
  # copy has no project.
  #
  # With key: nil, each bar is spelled by the tonal context in force there and
  # the timeline is kept. Any other key the speller takes spells the notes and
  # keeps the timeline too, except key: :infer, whose regions replace the key
  # signatures. A region with the signature of the one before, such as its
  # relative key, writes no change, since every change is printed.
  class Respelling
    # The regions whose signature differs from the one before, the first
    # always: those a flow's timeline writes.
    def self.signature_changes(regions)
      signature = nil
      regions.select do |region|
        fifths = HeadMusic::Content::Flow::Timeline.fifths_of(region.key.key_signature)
        changed = fifths != signature
        signature = fifths
        changed
      end
    end

    def initialize(flow, key: nil, **finder_options)
      @source = flow
      @input = HeadMusic::Analysis::NoteInput.for(flow)
      @key = key
      @finder_options = finder_options
      @speller = HeadMusic::Analysis::PitchSpeller.new(@input, key: @key.nil? ? timeline_regions : @key, **@finder_options)
    end

    def flow
      hash = @source.to_h
      speller.spelled_notes.zip(@input.addresses) do |spelled_note, address|
        hash.dig(*address[0...-1])[address.last] = spelled_note.pitch.to_s
      end
      write_key_signatures(hash["timeline"]) if @key == :infer && speller.regions.any?
      HeadMusic::Content::Flow.from_h(hash)
    end

    # The spelled notes and the addresses of their sounds in the flow's to_h,
    # in the order the flow's NoteInput reads them.
    def spelled_notes
      speller.spelled_notes
    end

    def addresses
      @input.addresses
    end

    private

    attr_reader :speller

    def timeline_regions
      timeline = @source.timeline
      @input.bar_starts.map do |bar_number, onset|
        key = timeline.tonal_context_at(bar_number) || timeline.key_signature_at(bar_number)
        HeadMusic::Analysis::KeyRegion.new(bar_number: bar_number, onset: onset, key: key)
      end
    end

    def write_key_signatures(timeline_hash)
      first, *later = self.class.signature_changes(speller.regions)
      timeline_hash["key_signature"] = first.key.name
      timeline_hash["key_signature_changes"] = later.map do |region|
        {"number" => region.bar_number, "signature" => fifths(region.key), "tonal_context" => region.key.name}
      end
    end

    def fifths(key)
      HeadMusic::Content::Flow::Timeline.fifths_of(key.key_signature)
    end
  end
end
