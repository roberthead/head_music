require "rexml/document"
require "rexml/xpath"

# XPath-based assertion helpers for MusicXML writer specs. Every rendered
# document must pass a REXML parse, so well-formedness is asserted for free.
module MusicXMLHelpers
  def parse_musicxml(xml)
    REXML::Document.new(xml)
  end

  def xpath_text(document, xpath)
    element = REXML::XPath.first(document, xpath)
    element&.text
  end

  def xpath_texts(document, xpath)
    REXML::XPath.match(document, xpath).map(&:text)
  end

  def xpath_count(document, xpath)
    REXML::XPath.match(document, xpath).length
  end
end

RSpec.configure do |config|
  config.include MusicXMLHelpers
end
