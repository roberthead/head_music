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

  def xpath_names(document, xpath)
    REXML::XPath.match(document, xpath).map(&:name)
  end

  def xpath_count(document, xpath)
    REXML::XPath.match(document, xpath).length
  end

  # The wedges a document writes, paired by number in document order as a
  # reader pairs them: each as [part id, voice number or nil, kind, where it
  # starts, where it stops], a place being [measure number, divisions into
  # the measure]. Under `:problems`, a stop with no wedge open on its
  # number, a start on a number still open, and a wedge never stopped.
  def wedge_summary(xml)
    wedges = []
    problems = []
    REXML::XPath.match(parse_musicxml(xml), "//part").each do |part|
      part_id = part.attributes["id"]
      open = {}
      wedge_directions(part).each do |direction, place|
        wedge = direction.elements["direction-type/wedge"]
        number = wedge.attributes["number"]
        voice = direction.elements["voice"]&.text
        if wedge.attributes["type"] == "stop"
          opened = open.delete(number)
          if opened
            wedges << [*opened, place]
          else
            problems << "#{part_id} stops wedge #{number} at #{place} with none open"
          end
        else
          problems << "#{part_id} starts wedge #{number} at #{place} while it is open" if open.key?(number)
          open[number] = [part_id, voice, wedge.attributes["type"], place]
        end
      end
      open.each_value { |opened| problems << "#{part_id} never stops the wedge from #{opened.last}" }
    end
    {wedges: wedges.sort_by(&:inspect), problems: problems}
  end

  # A flow's hairpins as wedge_summary describes them, with an end on the
  # final barline at the end of the last measure.
  def expected_wedges(flow)
    plan = HeadMusic::Notation::MusicXML::RenderPlan.new(flow)
    flow.parts.each_with_index.flat_map do |part, index|
      owners = [[nil, part], *part.voices.each_with_index.map { |voice, number| [(part.voices.length > 1) ? (number + 1).to_s : nil, voice] }]
      owners.flat_map do |voice_number, owner|
        owner.spans.select(&:hairpin?).map do |span|
          ["P#{index + 1}", voice_number, span.name_key, wedge_place(plan, span.from), wedge_place(plan, span.to)]
        end
      end
    end.sort_by(&:inspect)
  end

  private

  def wedge_directions(part)
    REXML::XPath.match(part, "measure").flat_map do |measure|
      cursor = 0
      measure.elements.each_with_object([]) do |element, directions|
        if element.name == "direction"
          place = [measure.attributes["number"].to_i, cursor + element.elements["offset"]&.text.to_i]
          directions << [element, place] if element.elements["direction-type/wedge"]
        else
          cursor += cursor_step(element)
        end
      end
    end
  end

  def cursor_step(element)
    duration = element.elements["duration"]&.text.to_i
    case element.name
    when "backup" then -duration
    when "forward" then duration
    when "note" then (element.elements["chord"] || element.elements["grace"]) ? 0 : duration
    else 0
    end
  end

  def wedge_place(plan, position)
    last_bar = plan.bar_numbers.last
    return [last_bar, plan.whole_measure_duration(last_bar)] if position == plan.flow.final_barline_position

    [position.bar_number, (exact_offset_in_bar(plan.flow, position) * 4 * plan.divisions).to_i]
  end

  # A note starting at a rounded position starts at its exact onset.
  def exact_offset_in_bar(flow, position)
    voice_event = flow.voices.filter_map { |voice| voice.voice_event_at(position) }.first
    return HeadMusic::Notation::BarSplitter.offset_in_bar(position) unless voice_event

    HeadMusic::Notation::BarSplitter.onset_in_bar(voice_event)
  end
end

RSpec.configure do |config|
  config.include MusicXMLHelpers
end
