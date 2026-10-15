module HeadMusic::Notation::MEI
  # An element to write: nil attributes are left out, and an element holds
  # either children or text.
  Element = Data.define(:name, :id, :attributes, :children, :text) do
    def initialize(name:, id: nil, attributes: {}, children: [], text: nil)
      super
    end
  end

  # An element an extension places in a bar.
  BarElement = Data.define(:bar_number, :element)

  # Serializes elements as indented lines.
  module Markup
    extend HeadMusic::Notation::XmlText

    module_function

    def lines(element, depth = 0)
      indent = HeadMusic::Notation::XmlText::INDENT * depth
      tag = "#{element.name}#{attribute_text(element)}"
      if element.children.any?
        ["#{indent}<#{tag}>", *element.children.flat_map { |child| lines(child, depth + 1) }, "#{indent}</#{element.name}>"]
      elsif element.text
        ["#{indent}<#{tag}>#{escape(element.text)}</#{element.name}>"]
      else
        ["#{indent}<#{tag}/>"]
      end
    end

    def attribute_text(element)
      {"xml:id" => element.id, **element.attributes}.filter_map do |name, value|
        %( #{name}="#{escape(value)}") unless value.nil?
      end.join
    end
  end
end
