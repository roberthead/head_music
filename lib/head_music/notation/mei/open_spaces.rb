module HeadMusic::Notation::MEI
  # A <space> with no @dur, and no @dur.default in force, takes the time
  # its layer leaves of the longest other layer in the measure, shared
  # equally among such spaces in the layer, the entries after each moving
  # later by its share. A layer of whole-bar rests is as long as its bar.
  # A share no single rest fills is left as a gap, which placing the voice
  # fills with rests. Where no other layer gives a length, as where every
  # layer holds such a space, the measure is as long as its meter.
  module OpenSpaces
    module_function

    def resolve(contents, meter)
      open, closed = contents.partition { |content| content.entries.any?(&:open_space?) }
      return if open.empty?

      length = closed.filter_map { |content| length_of(content, meter) }.max || Rational(meter.top_number, meter.bottom_number)
      open.each { |content| fill(content, length) }
    end

    def length_of(content, meter)
      return content.extent unless content.entries.any?(&:fills_bar?)

      [content.extent, Rational(meter.top_number, meter.bottom_number)].compact.max
    end

    def fill(content, length)
      count = content.entries.count(&:open_space?)
      share = [length - (content.extent || 0), 0].max / count
      value = share.positive? ? HeadMusic::Notation::DottedDuration.rest_value(share) : nil
      shift = 0
      content.entries.select! do |entry|
        entry.cursor += shift
        next true unless entry.open_space?

        shift += share
        entry.rhythmic_value = value
        entry.duration = share
        !value.nil?
      end
      content.extent = (content.extent || 0) + share * count
    end
  end
end
