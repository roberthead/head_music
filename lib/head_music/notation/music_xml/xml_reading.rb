# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads text and attributes from REXML elements. REXML expands entities
  # lazily, so a document past its expansion limits parses and then raises a
  # bare RuntimeError on the first read; every read goes through here so that
  # it raises ParseError instead.
  module XmlReading
    module_function

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

    MAX_NUMBER_LENGTH = 40

    # MusicXML's numbers are xs:decimal, which Rational reads exactly. An
    # exponent is no decimal, and a large one makes Rational warn and raise.
    def rational(text, label, **where)
      return if text.nil?
      raise ParseError.new(%(Unreadable #{label} "#{text[0, MAX_NUMBER_LENGTH]}"), **where) unless decimal?(text)

      Rational(text)
    rescue ArgumentError, ZeroDivisionError
      raise ParseError.new(%(Unreadable #{label} "#{text}"), **where)
    end

    def decimal?(text)
      text.length <= MAX_NUMBER_LENGTH && !text.match?(/e/i)
    end

    def integer(text, label, **where)
      return if text.nil?

      Integer(text, 10)
    rescue ArgumentError
      raise ParseError.new(%(Unreadable #{label} "#{text}"), **where)
    end

    def first_child(element, name)
      element.each_element { |child| return child if child.name == name }
      nil
    end

    def children(element, name)
      result = []
      element.each_element { |child| result << child if child.name == name }
      result
    end

    def raise_expansion(error, where)
      raise ParseError.new("MusicXML text exceeds the entity expansion limits (#{error.message})", **where)
    end
    private_class_method :decimal?, :raise_expansion
  end
end
