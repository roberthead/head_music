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

# Summaries of a document's tuplets, grace notes, and timing, read back as a
# MusicXML reader would and set beside what a flow should write. Named apart
# from TupletExpectations' flow summaries, which every spec also includes.
# Places are [measure number, divisions into the measure], and voices the
# <voice> a part with several writes, or nil.
module MusicXMLTupletHelpers
  ALTER_SIGNS = {-2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "x"}.freeze

  def musicxml_summaries(xml)
    {tuplets: musicxml_tuplet_summary(xml), graces: musicxml_grace_summary(xml), timing: musicxml_timing_summary(xml)}
  end

  def expected_musicxml_summaries(flow)
    plan = HeadMusic::Notation::MusicXML::RenderPlan.new(flow)
    {tuplets: expected_musicxml_tuplets(plan), graces: expected_musicxml_graces(plan), timing: expected_musicxml_timing(plan)}
  end

  # Each bracket as [part id, voice, start, end, ratio], its end where its
  # last note stops sounding; how many lead notes carry a
  # <time-modification>; and under `:problems`, a stop with no bracket
  # open, a start on an open number, a bracket never stopped, and a note
  # whose ratio is not its bracket's.
  def musicxml_tuplet_summary(xml)
    brackets = []
    problems = []
    open = {}
    modified = 0
    each_musicxml_note(xml) do |part_id, voice, note, place|
      next if note.elements["chord"] || note.elements["grace"]

      ratio = musicxml_ratio(note)
      modified += 1 if ratio
      tuplets = REXML::XPath.match(note, "notations/tuplet")
      tuplets.select { |tuplet| tuplet.attributes["type"] == "start" }.each do |tuplet|
        key = [part_id, tuplet.attributes["number"]]
        problems << "#{part_id} starts tuplet #{key.last} at #{place} while it is open" if open.key?(key)
        open[key] = [part_id, voice, place, ratio]
      end
      bracket = open.values.find { |opened| opened.first(2) == [part_id, voice] }
      problems << "the note at #{place} carries #{ratio.inspect} under a #{bracket.last} bracket" if bracket && bracket.last != ratio
      problems << "the #{ratio} note at #{place} is under no bracket" if ratio && !bracket
      tuplets.select { |tuplet| tuplet.attributes["type"] == "stop" }.each do |tuplet|
        opened = open.delete([part_id, tuplet.attributes["number"]])
        next problems << "#{part_id} stops tuplet #{tuplet.attributes["number"]} at #{place} with none open" unless opened

        brackets << [*opened.first(3), [place.first, place.last + note.elements["duration"].text.to_i], opened.last]
      end
    end
    open.each_value { |opened| problems << "#{opened.first} never stops the tuplet from #{opened[2]}" }
    {brackets: brackets.sort_by(&:inspect), modified: modified, problems: problems}
  end

  def expected_musicxml_tuplets(plan)
    brackets = []
    modified = 0
    each_flow_voice(plan.flow) do |part_id, voice_number, voice|
      HeadMusic::Notation::TupletBrackets.for(voice).each do |bracket|
        modified += bracket.links.length
        first = bracket.first
        last = bracket.last
        brackets << [
          part_id, voice_number,
          [first.bar_number, in_divisions(plan, first.onset.last)],
          [last.bar_number, in_divisions(plan, last.onset.last + last.rhythmic_value.link_fraction)],
          bracket.ratio.to_a.join(":")
        ]
      end
    end
    {brackets: brackets.sort_by(&:inspect), modified: modified, problems: []}
  end

  # Each run of grace notes as [part id, voice, the place of the note they
  # lead to, the grace notes], each grace note as [pitches, type, dots,
  # slashed, pitches tied onward, articulations, whether a slur starts on
  # it]. Under `:problems`, a grace note with a duration or a beam, and grace
  # notes leading to nothing.
  def musicxml_grace_summary(xml)
    runs = []
    problems = []
    pending = Hash.new { |hash, key| hash[key] = [] }
    each_musicxml_note(xml) do |part_id, voice, note, place|
      key = [part_id, voice]
      if note.elements["grace"]
        problems << "the grace note at #{place} has a duration or a beam" if note.elements["duration"] || note.elements["beam"]
        pending[key] << musicxml_grace(note) unless note.elements["chord"]
        musicxml_add_grace_pitch(pending[key].last, note)
      elsif !note.elements["chord"] && pending.key?(key)
        runs << [part_id, voice, place, pending.delete(key)]
      end
    end
    pending.each_key { |part_id, voice| problems << "grace notes in #{part_id} voice #{voice.inspect} lead to no note" }
    {runs: runs.sort_by { |run| [run.first, run[1].to_s, run[2]] }, problems: problems}
  end

  def expected_musicxml_graces(plan)
    runs = []
    each_flow_voice(plan.flow) do |part_id, voice_number, voice|
      voice.note_events.reject { |note_event| note_event.grace_notes.empty? }.each do |note_event|
        segment = HeadMusic::Notation::BarSplitter.segments_of(note_event).first
        place = [segment.bar_number, in_divisions(plan, segment.offset)]
        runs << [part_id, voice_number, place, expected_graces(voice, note_event)]
      end
    end
    {runs: runs.sort_by { |run| [run.first, run[1].to_s, run[2]] }, problems: []}
  end

  # The <divisions>, and every note and rest but a whole-measure rest as
  # [part id, voice, measure, onset, duration], in quarter notes.
  def musicxml_timing_summary(xml)
    divisions = REXML::XPath.first(parse_musicxml(xml), "//divisions").text.to_i
    notes = []
    each_musicxml_note(xml) do |part_id, voice, note, place|
      next if note.elements["chord"] || note.elements["grace"] || note.elements["rest[@measure='yes']"]

      notes << [part_id, voice, place.first, Rational(place.last, divisions), Rational(note.elements["duration"].text.to_i, divisions)]
    end
    {divisions: divisions, notes: notes.sort_by(&:inspect)}
  end

  # The smallest divisions that hold every written length, whole measure,
  # beat that beams group by, and mark exactly.
  def expected_musicxml_timing(plan)
    flow = plan.flow
    notes = []
    each_flow_voice(flow) do |part_id, voice_number, voice|
      HeadMusic::Notation::BarSplitter.segments(voice.voice_events).each do |segment|
        onset = Rational(segment.offset) * 4
        segment.rhythmic_duration.values.each do |link|
          notes << [part_id, voice_number, segment.bar_number, onset, link.link_fraction * 4]
          onset += link.link_fraction * 4
        end
      end
    end
    meters = [flow.meter, *flow.meter_changes.values].flat_map do |meter|
      [Rational(4 * meter.top_number, meter.bottom_number), meter.beam_group_unit.written_fraction * 4]
    end
    marks = (flow.parts + flow.voices).flat_map(&:dynamic_events).map { |event| exact_offset_in_bar(flow, event.position) * 4 }
    lengths = notes.map(&:last) + meters + marks
    {divisions: lengths.map(&:denominator).reduce(1, :lcm), notes: notes.sort_by(&:inspect)}
  end

  private

  def each_musicxml_note(xml)
    REXML::XPath.match(parse_musicxml(xml), "//part").each do |part|
      lead_place = nil
      REXML::XPath.match(part, "measure").each do |measure|
        cursor = 0
        measure.elements.each do |element|
          if element.name == "note"
            place = element.elements["chord"] ? lead_place : [measure.attributes["number"].to_i, cursor]
            lead_place = place
            yield part.attributes["id"], element.elements["voice"]&.text, element, place
          end
          cursor += cursor_step(element)
        end
      end
    end
  end

  def each_flow_voice(flow)
    flow.parts.each_with_index do |part, index|
      part.voices.each_with_index do |voice, number|
        yield "P#{index + 1}", (part.voices.length > 1) ? (number + 1).to_s : nil, voice
      end
    end
  end

  def musicxml_ratio(note)
    modification = note.elements["time-modification"]
    modification && "#{modification.elements["actual-notes"].text}:#{modification.elements["normal-notes"].text}"
  end

  def musicxml_grace(note)
    [
      [], note.elements["type"].text, xpath_count(note, "dot"), note.elements["grace"].attributes["slash"] == "yes", [],
      xpath_names(note, "notations/articulations/*"), !note.elements["notations/slur[@type='start']"].nil?
    ]
  end

  def musicxml_add_grace_pitch(grace, note)
    pitch = note.elements["pitch"]
    label = musicxml_pitch_label(pitch.elements["step"].text, pitch.elements["alter"]&.text.to_i, pitch.elements["octave"].text)
    grace[0] << label
    grace[4] << label if note.elements["tie[@type='start']"]
  end

  def expected_graces(voice, note_event)
    graces = note_event.grace_notes
    graces.each_with_index.map do |grace, index|
      labels = grace.pitches.sort.map { |pitch| flow_pitch_label(pitch) }
      follower = (graces[index + 1]&.pitches || note_event.pitches).map { |pitch| flow_pitch_label(pitch) }
      slur = index.zero? && voice.spans.any? { |span| span.from_grace? && span.from == note_event.position }
      [
        labels, HeadMusic::Notation::MusicXML::DurationWriter::TYPES_BY_UNIT_NAME.fetch(grace.rhythmic_value.unit_name),
        grace.rhythmic_value.dots, grace.slashed?, grace.tied? ? labels & follower : [],
        grace.articulations.map { |articulation| HeadMusic::Notation::MusicXML::MarkingElements.articulation_element(articulation) }, slur
      ]
    end
  end

  def flow_pitch_label(pitch)
    musicxml_pitch_label(pitch.letter_name.to_s, pitch.alteration_semitones.to_i, pitch.register.to_s)
  end

  def musicxml_pitch_label(step, alter, octave)
    "#{step}#{ALTER_SIGNS.fetch(alter)}#{octave}"
  end

  # An Integer where the fraction of a whole note is a whole number of
  # divisions, and the Rational otherwise, so a mismatch shows.
  def in_divisions(plan, fraction)
    divisions = fraction * 4 * plan.divisions
    (divisions.denominator == 1) ? divisions.to_i : divisions
  end
end

RSpec.configure do |config|
  config.include MusicXMLHelpers
  config.include MusicXMLTupletHelpers
end
