class HeadMusic::Content::Flow
  # The checks shared by the schema value validators. Each raises
  # ArgumentError with the path the value came from.
  module SchemaValidation
    KIND_NAMES = {Array => "an Array", Hash => "a Hash"}.freeze

    private

    # The rudiment getters raise on some garbage and answer a hollow object on
    # the rest, so a validator treats both the same way: as nil, then checks.
    def attempt
      yield
    rescue
      nil
    end

    # Answers the validated elements, each yielded with its path.
    def each_element(values, label, path)
      ensure_kind!(values, Array, label, path)
      values.each_with_index.map do |value, index|
        yield value, "#{path}.#{label}[#{index}]"
      end
    end

    # An absent list is an empty one.
    def each_optional_element(values, label, path, &)
      return [] if values.nil?

      each_element(values, label, path, &)
    end

    def ensure_kind!(value, kind, label, path)
      raise ArgumentError, "#{path}: #{label} must be #{KIND_NAMES[kind]}, got #{value.inspect}" unless value.is_a?(kind)
    end

    def catalog_value(value, catalog, path)
      entry = catalog.get(value) if value.is_a?(String)
      raise ArgumentError, "#{path}: unknown #{catalog.name.demodulize.underscore.tr("_", " ")} #{value.inspect}" unless entry

      entry
    end

    def non_empty_string?(value)
      value.is_a?(String) && !value.empty?
    end
  end
end
