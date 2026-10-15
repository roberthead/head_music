require "rexml/document"

# A module for visual music notation
module HeadMusic::Notation
  # Reads text and attributes from REXML elements. REXML expands entities
  # lazily, so a document past its expansion limits parses and then raises a
  # bare RuntimeError on the first read; every read goes through here so that
  # it raises the format's ParseError instead.
  #
  # XmlReading.for(error_class, format:) builds a module for one format, which
  # can be included or called directly.
  module XmlReading
    MAX_NUMBER_LENGTH = 40

    def self.for(error_class, format:)
      Module.new do
        include Methods

        const_set(:MAX_NUMBER_LENGTH, MAX_NUMBER_LENGTH)
        define_method(:xml_error_class) { error_class }
        define_method(:xml_format) { format }
        module_function(*Methods.instance_methods, :xml_error_class, :xml_format)
        private_class_method :decimal?, :raise_expansion, :xml_error_class, :xml_format
      end
    end

    # The readers each format's module holds.
    module Methods
      # The stripped text of an element, or of its first child of a name, or
      # nil where there is none.
      def text(element, child = nil, **where)
        element = (element && child) ? first_child(element, child) : element
        element&.text&.strip
      rescue RuntimeError => error
        raise_expansion(error, where)
      end

      def attribute(element, name, **where)
        element&.attributes&.[](name)&.strip
      rescue RuntimeError => error
        raise_expansion(error, where)
      end

      # XML's numbers are xs:decimal, which Rational reads exactly. An
      # exponent is no decimal, and a large one makes Rational warn and raise.
      def rational(text, label, **where)
        return if text.nil?
        raise xml_error_class.new(%(Unreadable #{label} "#{text[0, MAX_NUMBER_LENGTH]}"), **where) unless decimal?(text)

        Rational(text)
      rescue ArgumentError, ZeroDivisionError
        raise xml_error_class.new(%(Unreadable #{label} "#{text}"), **where)
      end

      def decimal?(text)
        text.length <= MAX_NUMBER_LENGTH && !text.match?(/e/i)
      end

      def integer(text, label, **where)
        return if text.nil?

        Integer(text, 10)
      rescue ArgumentError
        raise xml_error_class.new(%(Unreadable #{label} "#{text}"), **where)
      end

      # REXML's each_element goes through XPath, so children are walked
      # directly.
      def first_child(element, name)
        element.each { |child| return child if child.is_a?(REXML::Element) && child.name == name }
        nil
      end

      def children(element, name)
        result = []
        element.each { |child| result << child if child.is_a?(REXML::Element) && child.name == name }
        result
      end

      def raise_expansion(error, where)
        raise xml_error_class.new("#{xml_format} text exceeds the entity expansion limits (#{error.message})", **where)
      end
    end
  end
end
