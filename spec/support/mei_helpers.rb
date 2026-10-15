require "rexml/document"
require "rexml/xpath"

# XPath helpers for MEI writer specs, with the MEI namespace bound to "mei".
# Every rendered document must pass a REXML parse, so well-formedness is
# asserted for free.
module MEIHelpers
  MEI_NAMESPACE = {"mei" => "http://www.music-encoding.org/ns/mei"}.freeze

  # Every fixture flow the notation specs share, by name, each built fresh.
  # Those the writer refuses are listed with the reason it gives.
  def self.sample_flows
    modules = [LilyPondFixtures, MarkingFixtures, NavigationFixtures, TupletFixtures, HairpinFixtures]
    builders = modules.flat_map do |fixtures|
      fixtures.singleton_methods.sort.filter_map do |name|
        next if %i[all crossing_barline].include?(name) || !fixtures.method(name).arity.zero?

        ["#{fixtures.name}.#{name}", -> { fixtures.public_send(name) }]
      end
    end
    kern = Dir[File.join(__dir__, "..", "fixtures", "notation", "kern", "*.krn")].sort.map do |path|
      ["kern/#{File.basename(path)}", -> { HeadMusic::Notation::Kern.parse(File.read(path)) }]
    end
    (builders + kern).to_h
  end

  REFUSED_SAMPLES = {
    "LilyPondFixtures.tacet" => /no voice events/
  }.freeze

  def parse_mei(xml)
    REXML::Document.new(xml)
  end

  def mei_elements(document, xpath)
    REXML::XPath.match(document, xpath, MEI_NAMESPACE)
  end

  def mei_element(document, xpath)
    REXML::XPath.first(document, xpath, MEI_NAMESPACE)
  end

  def mei_attributes(document, xpath, *names)
    mei_elements(document, xpath).map do |element|
      values = names.map { |name| element.attributes[name] }
      (names.length == 1) ? values.first : values
    end
  end

  def mei_attribute_hash(element)
    attributes = {}
    element.attributes.each_attribute { |attribute| attributes[attribute.expanded_name] = attribute.value }
    attributes
  end

  def mei_ids(document)
    REXML::XPath.match(document, "//@xml:id").map(&:value)
  end

  def mei_element_by_id(document, id)
    mei_elements(document, "//*").find { |element| element.attributes["xml:id"] == id }
  end

  # Duplicate ids, and references that name no element, as messages.
  def mei_reference_problems(document)
    ids = mei_ids(document)
    duplicates = ids.tally.select { |_, count| count > 1 }.keys.map { |id| "#{id} is not unique" }
    references = REXML::XPath.match(document, "//@startid | //@endid | //@plist")
      .flat_map { |attribute| attribute.value.split.map { |reference| [attribute.name, reference] } }
    unresolved = references.filter_map do |name, reference|
      "@#{name} #{reference} names no element" unless reference.start_with?("#") && ids.include?(reference[1..])
    end
    duplicates + unresolved
  end

  # Elements from <mdiv> down that carry no xml:id.
  def mei_elements_without_ids(document)
    mei_elements(document, "//mei:mdiv/descendant-or-self::*").reject { |element| element.attributes["xml:id"] }.map(&:name)
  end
end

RSpec.configure do |config|
  config.include MEIHelpers
end
