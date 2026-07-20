# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a HeadMusic::Content::Composition as a score-partwise MusicXML 4.0
  # document string.
  #
  # Whole-composition problems (no voices, positional gaps, barline-crossing
  # notes, unmappable keys or durations, forbidden control characters) raise
  # before any assembly, so #to_s only ever returns a complete document.
  class Writer
    INDENT = "  "
    XML_ESCAPES = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      "'" => "&apos;"
    }.freeze
    # The number of beams a notehead of each MusicXML <type> carries alone.
    # Every other type (quarter and longer) and every rest carries none.
    BEAM_LEVELS_BY_TYPE = {
      "eighth" => 1,
      "16th" => 2,
      "32nd" => 3,
      "64th" => 4,
      "128th" => 5,
      "256th" => 6
    }.freeze

    include HeadMusic::Notation::PlacementValidation

    attr_reader :composition

    def initialize(composition)
      @composition = composition
    end

    def to_s
      Preflight.check!(composition)
      memoize_render_data
      document_lines.join("\n") + "\n"
    end

    private

    # Preflight has already rejected unrenderable compositions and normalized
    # bar markers; everything else that can raise is computed here, before
    # assembly starts, and memoized for reuse during assembly.
    def memoize_render_data
      key_element_values(composition.key_signature)
      first_measure_key
      first_measure_meter
      measure_key_changes
      measure_time_changes
      components_by_placement
    end

    def divisions
      @divisions ||= Divisions.for(composition)
    end

    def duration_writer
      @duration_writer ||= DurationWriter.new(divisions)
    end

    def components_by_placement
      @components_by_placement ||= composition.voices.flat_map(&:placements).to_h do |placement|
        [placement, duration_writer.components(placement.rhythmic_value)]
      end
    end

    # A Hash keyed by [placement, component_index] holding the Array<Beam>
    # that BeamGrouper computed for that notehead. Built one bar at a time so
    # a notehead's onset is its exact integer offset from the bar start.
    def beam_annotations
      @beam_annotations ||= {}.tap do |annotations|
        composition.voices.each do |voice|
          bar_numbers.each { |bar_number| annotate_bar(voice, bar_number, annotations) }
        end
      end
    end

    def annotate_bar(voice, bar_number, annotations)
      placements = placements_by_bar(voice)[bar_number]
      return unless placements

      keys = []
      events = build_bar_events(placements, keys)
      beams = BeamGrouper.annotate(events, group_unit_divisions(bar_number))
      keys.each_with_index { |key, index| annotations[key] = beams[index] }
    end

    def build_bar_events(placements, keys)
      onset = 0
      placements.flat_map do |placement|
        components_by_placement[placement].each_with_index.map do |component, component_index|
          event = BeamGrouper::Event.new(
            levels: beam_levels(placement, component),
            onset: onset,
            beam_break_before: component_index.zero? ? placement.beam_break_before : nil
          )
          keys << [placement, component_index]
          onset += component.duration
          event
        end
      end
    end

    def beam_levels(placement, component)
      return 0 if placement.rest?

      BEAM_LEVELS_BY_TYPE.fetch(component.type, 0)
    end

    # The beam-group span in integer divisions for a bar's effective meter.
    # DurationWriter.single_quarter_fraction returns an exact Rational, so the
    # product with the integer divisions is integral for every supported meter.
    def group_unit_divisions(bar_number)
      fraction = DurationWriter.single_quarter_fraction(effective_meter(bar_number).beam_group_unit) * divisions
      unless fraction.denominator == 1
        raise RenderError,
          "cannot express the beam group unit as an integer duration at #{divisions} divisions per quarter note"
      end
      fraction.to_i
    end

    def bar_numbers
      composition.earliest_bar_number..composition.latest_bar_number
    end

    def measure_key_changes
      @measure_key_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
        [bar_number, key_element_values(bar.key_signature)] if bar.key_signature
      }.to_h
    end

    def measure_time_changes
      @measure_time_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
        [bar_number, bar.meter] if bar.meter
      }.to_h
    end

    def key_element_values(key_signature)
      {fifths: KeyMapper.fifths(key_signature), mode: KeyMapper.mode(key_signature)}
    end

    def first_measure_key
      @first_measure_key ||=
        measure_key_changes[bar_numbers.first] || key_element_values(composition.key_signature)
    end

    def first_measure_meter
      @first_measure_meter ||= effective_meter(bar_numbers.first)
    end

    def effective_meter(bar_number)
      change_bar = measure_time_changes.keys.select { |number| number <= bar_number }.max
      change_bar ? measure_time_changes[change_bar] : composition.meter
    end

    def document_lines
      [
        %(<?xml version="1.0" encoding="UTF-8"?>),
        %(<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">),
        %(<score-partwise version="4.0">),
        *work_lines,
        *identification_lines,
        *part_list_lines,
        *part_lines,
        "</score-partwise>"
      ]
    end

    def work_lines
      [
        "#{INDENT}<work>",
        "#{INDENT * 2}<work-title>#{escape(composition.name)}</work-title>",
        "#{INDENT}</work>"
      ]
    end

    def identification_lines
      [
        "#{INDENT}<identification>",
        composition.composer && %(#{INDENT * 2}<creator type="composer">#{escape(composition.composer)}</creator>),
        "#{INDENT * 2}<encoding>",
        "#{INDENT * 3}<software>head_music #{HeadMusic::VERSION}</software>",
        "#{INDENT * 2}</encoding>",
        "#{INDENT}</identification>"
      ].compact
    end

    def part_list_lines
      score_part_lines = composition.voices.each_with_index.flat_map do |voice, index|
        [
          %(#{INDENT * 2}<score-part id="P#{index + 1}">),
          "#{INDENT * 3}<part-name>#{escape(part_name(voice, index))}</part-name>",
          "#{INDENT * 2}</score-part>"
        ]
      end
      ["#{INDENT}<part-list>", *score_part_lines, "#{INDENT}</part-list>"]
    end

    def part_name(voice, index)
      voice.role || "Voice #{index + 1}"
    end

    def part_lines
      composition.voices.each_with_index.flat_map do |voice, index|
        [
          %(#{INDENT}<part id="P#{index + 1}">),
          *bar_numbers.flat_map { |bar_number| measure_lines(voice, bar_number) },
          "#{INDENT}</part>"
        ]
      end
    end

    def measure_lines(voice, bar_number)
      [
        measure_open_tag(bar_number),
        *attribute_lines(voice, bar_number),
        *measure_content_lines(voice, bar_number),
        "#{INDENT * 2}</measure>"
      ]
    end

    # A bar before bar 1 — a pickup written out in full with leading rests —
    # is marked implicit by convention. A partially filled first bar is
    # rejected as a gap in validate!, so only complete pickup bars reach here.
    def measure_open_tag(bar_number)
      implicit = (bar_number < 1) ? %( implicit="yes") : ""
      %(#{INDENT * 2}<measure number="#{bar_number}"#{implicit}>)
    end

    def attribute_lines(voice, bar_number)
      return first_measure_attribute_lines(voice) if bar_number == bar_numbers.first

      key = measure_key_changes[bar_number]
      meter = measure_time_changes[bar_number]
      return [] unless key || meter

      [
        "#{INDENT * 3}<attributes>",
        *(key ? key_lines(key) : []),
        *(meter ? time_lines(meter) : []),
        "#{INDENT * 3}</attributes>"
      ]
    end

    def first_measure_attribute_lines(voice)
      [
        "#{INDENT * 3}<attributes>",
        "#{INDENT * 4}<divisions>#{divisions}</divisions>",
        *key_lines(first_measure_key),
        *time_lines(first_measure_meter),
        *clef_lines(voice),
        "#{INDENT * 3}</attributes>"
      ]
    end

    def key_lines(key)
      [
        "#{INDENT * 4}<key>",
        "#{INDENT * 5}<fifths>#{key[:fifths]}</fifths>",
        "#{INDENT * 5}<mode>#{key[:mode]}</mode>",
        "#{INDENT * 4}</key>"
      ]
    end

    def time_lines(meter)
      [
        "#{INDENT * 4}<time>",
        "#{INDENT * 5}<beats>#{meter.top_number}</beats>",
        "#{INDENT * 5}<beat-type>#{meter.bottom_number}</beat-type>",
        "#{INDENT * 4}</time>"
      ]
    end

    def clef_lines(voice)
      clef = ClefSelector.for(voice)
      [
        "#{INDENT * 4}<clef>",
        "#{INDENT * 5}<sign>#{clef.pitch.letter_name}</sign>",
        "#{INDENT * 5}<line>#{clef.line}</line>",
        "#{INDENT * 4}</clef>"
      ]
    end

    def measure_content_lines(voice, bar_number)
      placements = placements_by_bar(voice)[bar_number]
      return whole_measure_rest_lines(bar_number) unless placements

      placements.flat_map { |placement| note_lines(placement) }
    end

    def placements_by_bar(voice)
      @placements_by_bar ||= {}
      @placements_by_bar[voice] ||= voice.placements.group_by { |placement| placement.position.bar_number }
    end

    def whole_measure_rest_lines(bar_number)
      [
        "#{INDENT * 3}<note>",
        %(#{INDENT * 4}<rest measure="yes"/>),
        "#{INDENT * 4}<duration>#{whole_measure_duration(bar_number)}</duration>",
        "#{INDENT * 3}</note>"
      ]
    end

    # Divisions.for guarantees a whole measure of any effective meter is an
    # integer number of divisions, so the Rational's numerator is the value.
    def whole_measure_duration(bar_number)
      meter = effective_meter(bar_number)
      (Rational(4 * meter.top_number, meter.bottom_number) * divisions).numerator
    end

    def note_lines(placement)
      ensure_pitched_sounds(placement)

      components_by_placement[placement].each_with_index.flat_map do |component, component_index|
        beams = beam_annotations[[placement, component_index]] || []
        note_slots(placement).each_with_index.flat_map do |pitch, index|
          note_element_lines(
            placement, component, pitch: pitch, chord: index.positive?, beams: index.zero? ? beams : []
          )
        end
      end
    end

    # A rest emits one empty slot; a sounded placement emits its pitches low to
    # high, so the lowest note leads and the rest carry <chord/>. ensure_pitched_sounds
    # has already rejected any unpitched sound, so pitches covers every sound here.
    def note_slots(placement)
      placement.rest? ? [nil] : placement.pitches.sort
    end

    def render_error_class
      RenderError
    end

    # A chord note carries <chord/> as its first child, before <pitch>, marking
    # it as sounding with the preceding note; the lead note (and every single
    # note and rest) omits it, so this path stays byte-identical for those.
    def note_element_lines(placement, component, pitch: nil, chord: false, beams: [])
      [
        "#{INDENT * 3}<note>",
        *(chord ? ["#{INDENT * 4}<chord/>"] : []),
        *(pitch ? pitch_lines(pitch) : ["#{INDENT * 4}<rest/>"]),
        "#{INDENT * 4}<duration>#{component.duration}</duration>",
        *tie_lines(placement, component),
        "#{INDENT * 4}<type>#{component.type}</type>",
        *Array.new(component.dots) { "#{INDENT * 4}<dot/>" },
        *beam_lines(beams),
        *notation_lines(placement, component),
        "#{INDENT * 3}</note>"
      ]
    end

    def beam_lines(beams)
      beams.map { |beam| %(#{INDENT * 4}<beam number="#{beam.number}">#{beam.type}</beam>) }
    end

    def pitch_lines(pitch)
      attributes = PitchWriter.attributes(pitch)
      [
        "#{INDENT * 4}<pitch>",
        "#{INDENT * 5}<step>#{attributes[:step]}</step>",
        attributes[:alter] && "#{INDENT * 5}<alter>#{attributes[:alter]}</alter>",
        "#{INDENT * 5}<octave>#{attributes[:octave]}</octave>",
        "#{INDENT * 4}</pitch>"
      ].compact
    end

    # Rests take no tie elements; the links of a rest's tied chain render as
    # consecutive independent rests.
    def tie_lines(placement, component)
      return [] if placement.rest?

      [
        component.tie_stop ? %(#{INDENT * 4}<tie type="stop"/>) : nil,
        component.tie_start ? %(#{INDENT * 4}<tie type="start"/>) : nil
      ].compact
    end

    def notation_lines(placement, component)
      return [] if placement.rest? || (!component.tie_start && !component.tie_stop)

      [
        "#{INDENT * 4}<notations>",
        component.tie_stop ? %(#{INDENT * 5}<tied type="stop"/>) : nil,
        component.tie_start ? %(#{INDENT * 5}<tied type="start"/>) : nil,
        "#{INDENT * 4}</notations>"
      ].compact
    end

    def escape(text)
      text.to_s.gsub(/[&<>"']/) { |character| XML_ESCAPES[character] }
    end
  end
end
