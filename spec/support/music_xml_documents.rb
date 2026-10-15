# Builds MusicXML documents from measure snippets, for reader specs that need
# what the writer never emits: string voices, <tied> without <tie>, negative
# offsets, per-staff <transpose>, split measures, and malformed input.
#
# A part is an Array of measures, and a measure is its inner XML, or
# [inner XML, {number:, implicit:}]. Measures are numbered from 1 unless
# they say otherwise. Pass `attributes: false` to leave out the opening
# attributes the first measure otherwise gets.
module MusicXMLDocuments
  PARTWISE_DOCTYPE = %(<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" ) +
    %("http://www.musicxml.org/dtds/partwise.dtd">)

  def musicxml_document(*parts, header: "", doctype: PARTWISE_DOCTYPE, attributes: opening_attributes, names: nil)
    names ||= parts.each_index.map { |index| "Part #{index + 1}" }
    [
      %(<?xml version="1.0" encoding="UTF-8"?>),
      doctype,
      %(<score-partwise version="4.0">),
      header,
      "<part-list>",
      *names.each_with_index.map { |name, index| score_part_xml("P#{index + 1}", name) },
      "</part-list>",
      *parts.each_with_index.map { |measures, index| part_xml("P#{index + 1}", measures, attributes) },
      "</score-partwise>"
    ].compact.join("\n") + "\n"
  end

  # One part of the given measures.
  def musicxml_measures(*measures, **options)
    musicxml_document(measures, **options)
  end

  def score_part_xml(id, name)
    name ? %(<score-part id="#{id}"><part-name>#{name}</part-name></score-part>) : %(<score-part id="#{id}"/>)
  end

  def part_xml(id, measures, attributes = opening_attributes)
    body = measures.each_with_index.map do |measure, index|
      content, options = Array(measure)
      options ||= {}
      number = options.fetch(:number, index + 1)
      implicit = options[:implicit] ? %( implicit="yes") : ""
      opening = (index.zero? && attributes) ? attributes : ""
      %(<measure number="#{number}"#{implicit}>#{opening}#{content}</measure>)
    end
    %(<part id="#{id}">\n#{body.join("\n")}\n</part>)
  end

  def opening_attributes(divisions: 1, fifths: 0, mode: nil, beats: 4, beat_type: 4, clef: %w[G 2], extra: "")
    key = "<key><fifths>#{fifths}</fifths>#{mode && "<mode>#{mode}</mode>"}</key>"
    time = beats && "<time><beats>#{beats}</beats><beat-type>#{beat_type}</beat-type></time>"
    clef_xml = clef && "<clef><sign>#{clef[0]}</sign><line>#{clef[1]}</line></clef>"
    "<attributes><divisions>#{divisions}</divisions>#{key}#{time}#{extra}#{clef_xml}</attributes>"
  end

  # A pitch such as "C4", "F#5", or "Bb3", or nil for a rest.
  def note_xml(pitch, duration, type = nil, dots: 0, voice: nil, staff: nil, chord: false, inside: "", after: "", notations: "")
    [
      "<note>",
      chord ? "<chord/>" : "",
      pitch ? pitch_xml(pitch) : "<rest/>",
      duration && "<duration>#{duration}</duration>",
      inside,
      voice && "<voice>#{voice}</voice>",
      type && "<type>#{type}</type>",
      "<dot/>" * dots,
      after,
      staff && "<staff>#{staff}</staff>",
      notations.empty? ? "" : "<notations>#{notations}</notations>",
      "</note>"
    ].compact.join
  end

  def rest_xml(duration, type = nil, **options)
    note_xml(nil, duration, type, **options)
  end

  def measure_rest_xml(duration, voice: nil, staff: nil)
    [
      %(<note><rest measure="yes"/><duration>#{duration}</duration>),
      voice && "<voice>#{voice}</voice>",
      staff && "<staff>#{staff}</staff>",
      "</note>"
    ].compact.join
  end

  def pitch_xml(pitch)
    step, accidental, octave = pitch.match(/\A([A-G])(#|b|x|bb)?(-?\d)\z/).captures
    alter = {"#" => 1, "b" => -1, "x" => 2, "bb" => -2}[accidental]
    "<pitch><step>#{step}</step>#{alter && "<alter>#{alter}</alter>"}<octave>#{octave}</octave></pitch>"
  end

  def backup_xml(duration)
    "<backup><duration>#{duration}</duration></backup>"
  end

  def forward_xml(duration, voice: nil)
    "<forward><duration>#{duration}</duration>#{voice && "<voice>#{voice}</voice>"}</forward>"
  end

  def parse_musicxml_flow(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end
end

RSpec.configure { |config| config.include MusicXMLDocuments }
