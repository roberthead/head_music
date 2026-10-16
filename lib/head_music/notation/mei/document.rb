module HeadMusic::Notation::MEI
  # A parsed MEI document as the scores in its body, each a Source: a leaf
  # <mdiv> holding a <score>, or a <parts> of one <part>, which reads as a
  # score. Only <music>/<body> is searched, so an incipit's <score> in the
  # <meiHead> is never read. Nested <mdiv>s, the <music> of a <group>, and
  # each <mei> of a <meiCorpus> are descended in document order. A <score>
  # straight in <music>, as MEI 2013 allowed, reads as one <mdiv>.
  #
  # Each <music> is scanned once before anything is read: its ids are
  # indexed, and mensural, neume, and tablature notation raise for the whole
  # document, since skipping them would leave no music to read.
  class Document
    include XmlReading

    Source = Data.define(:mdiv, :score, :labels, :head, :index, :editorial)

    NOTATION_ELEMENTS = %w[mensur ligature neume nc tabGrp].freeze
    NOTATION_TYPES = /\A(mensural|neume|tab)/

    attr_reader :root

    def initialize(xml)
      @root = xml.root
    end

    def sources
      @sources ||= find_sources.tap do |found|
        raise ParseError, "MEI input has no <score> or <part> in its <body>" if found.empty?
      end
    end

    private

    def find_sources
      documents.flat_map do |mei, head|
        music = (mei.name == "music") ? mei : first_child(mei, "music")
        raise ParseError, "MEI input has no <music>" unless music

        index = scan(music)
        editorial = Editorial.new(index, budget: 4 * @count)
        music_sources(music, [], head, index, editorial)
      end
    end

    # Each document with its <meiHead>, a corpus's own head standing in for
    # a document that has none.
    def documents
      case root.name
      when "music" then [[root, nil]]
      when "meiCorpus"
        corpus_head = first_child(root, "meiHead")
        children(root, "mei").map { |mei| [mei, first_child(mei, "meiHead") || corpus_head] }
      else [[root, first_child(root, "meiHead")]]
      end
    end

    def music_sources(music, labels, head, index, editorial)
      labels = [present(attribute(music, "label")), *labels].compact
      editorial.children(music).flat_map do |child|
        case child.name
        when "body" then editorial.children_named(child, "mdiv").flat_map { |mdiv| mdiv_sources(mdiv, labels, head, index, editorial) }
        when "group" then editorial.children_named(child, "music").flat_map { |inner| music_sources(inner, labels, head, index, editorial) }
        when "score" then [Source.new(music, child, labels, head, index, editorial)]
        else []
        end
      end
    end

    def mdiv_sources(mdiv, labels, head, index, editorial)
      editorial.children(mdiv).flat_map do |child|
        case child.name
        when "score" then [Source.new(mdiv, child, labels, head, index, editorial)]
        when "parts" then [Source.new(mdiv, single_part(child, editorial), labels, head, index, editorial)]
        when "mdiv" then mdiv_sources(child, labels, head, index, editorial)
        else []
        end
      end
    end

    def single_part(parts, editorial)
      found = editorial.children_named(parts, "part")
      raise ParseError.new("A <parts> holds no <part>", element: parts) if found.empty?
      if found.length > 1
        raise UnsupportedFeatureError.new("A <parts> of #{found.length} <part>s is not supported; only a single part reads as a score", element: parts)
      end

      found.first
    end

    # One walk over every element in document order, with an explicit stack.
    def scan(music)
      index = IdIndex.new
      @count = 0
      stack = [[music, nil]]
      until stack.empty?
        element, measure = stack.pop
        @count += 1
        measure = attribute(element, "n", element: element) || measure if element.name == "measure"
        check_notation(element, measure)
        id = attribute(element, "xml:id", element: element, measure: measure)
        index.register(id, element) if id
        pending = []
        element.each { |child| pending << [child, measure] if child.is_a?(REXML::Element) }
        stack.concat(pending.reverse)
      end
      index
    end

    def check_notation(element, measure)
      if NOTATION_ELEMENTS.include?(element.name)
        raise UnsupportedFeatureError.new("MEI <#{element.name}> notation is not supported", measure: measure, element: element)
      end

      type = attribute(element, "notationtype", element: element, measure: measure)
      return unless type&.match?(NOTATION_TYPES)

      raise UnsupportedFeatureError.new(%(MEI notationtype="#{type[0, 40]}" is not supported), measure: measure, element: element)
    end

    def present(text)
      text unless text.to_s.empty?
    end
  end
end
