class HeadMusic::Analysis::PitchSpeller
  # The key regions a speller's key: names, and the key center in force at
  # each onset. Where there are no regions, the notes are spelled in C major.
  class KeyCenters
    attr_reader :regions

    def initialize(input, key:, **finder_options)
      raise ArgumentError, "#{finder_options.keys.join(", ")} apply only to key: :infer" if finder_options.any? && key != :infer

      @input = input
      @finder_options = finder_options
      @regions = regions_for(key).sort_by(&:onset).freeze
      @spelling_regions = @regions.empty? ? [region_at_first_bar(DEFAULT_KEY)] : @regions
      @key_centers = {}
    end

    def at(onset)
      following = @spelling_regions.bsearch_index { |region| region.onset > onset }
      region = @spelling_regions[[(following || @spelling_regions.length) - 1, 0].max]
      @key_centers[region.key] ||= KeyCenter.for(region.key)
    end

    private

    def regions_for(key)
      case key
      when :infer then HeadMusic::Analysis::KeyFinder.new(@input, **@finder_options).regions
      when Array then key_regions(key)
      else [region_at_first_bar(tonal_context(key))]
      end
    end

    def key_regions(regions)
      raise ArgumentError, "key: needs at least one key region" if regions.empty?

      regions.map do |region|
        raise ArgumentError, "expected a KeyRegion, got #{region.inspect}" unless region.is_a?(HeadMusic::Analysis::KeyRegion)

        region.with(key: tonal_context(region.key))
      end
    end

    def region_at_first_bar(key)
      first_bar, onset = @input.bar_starts.first
      HeadMusic::Analysis::KeyRegion.new(bar_number: first_bar, onset: onset, key: key)
    end

    def tonal_context(key)
      case key
      when HeadMusic::Rudiment::DiatonicContext, HeadMusic::Rudiment::KeySignature then key
      when String, Symbol then named_tonal_context(key.to_s)
      else raise ArgumentError, "expected a key, a mode, or key regions, got #{key.inspect}"
      end
    end

    def named_tonal_context(name)
      qualifier = name.split.last.to_s.downcase.to_sym
      context_class = HeadMusic::Rudiment::Mode::MODES.include?(qualifier) ? HeadMusic::Rudiment::Mode : HeadMusic::Rudiment::Key
      context = context_class.get(name)
      raise ArgumentError, "unknown key #{name.inspect}" unless context.tonic_spelling

      context
    end
  end
end
