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
    include HeadMusic::Notation::PlacementValidation

    attr_reader :composition

    # The rendering facts the serialization methods below read; RenderPlan
    # computes them from the composition.
    delegate(
      :divisions, :components_by_placement, :beam_annotations, :bar_numbers,
      :measure_key_changes, :measure_time_changes, :first_measure_key,
      :first_measure_meter, :effective_meter, :placements_by_bar,
      :whole_measure_duration,
      to: :plan
    )

    def initialize(composition)
      @composition = composition
    end

    def to_s
      Preflight.check!(composition)
      plan
      document_lines.join("\n") + "\n"
    end

    private

    # The computed rendering facts. Built here — before assembly — so an
    # unmappable key or duration raises before any output is produced.
    def plan
      @plan ||= RenderPlan.new(composition)
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
    # rejected as a gap in Preflight, so only complete pickup bars reach here.
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

    def whole_measure_rest_lines(bar_number)
      [
        "#{INDENT * 3}<note>",
        %(#{INDENT * 4}<rest measure="yes"/>),
        "#{INDENT * 4}<duration>#{whole_measure_duration(bar_number)}</duration>",
        "#{INDENT * 3}</note>"
      ]
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
        *lyric_lines(placement, component, chord: chord),
        "#{INDENT * 3}</note>"
      ]
    end

    # <lyric> is the last child of <note>. Sung text rides only the lead note
    # of a chord and only the attack of a tied chain (a tie_stop component is a
    # continuation, sung once at the start). Held notes of a melisma carry no
    # syllable and so emit nothing, matching MusicXML's continuation-by-absence.
    def lyric_lines(placement, component, chord:)
      return [] if chord || placement.rest? || component.tie_stop

      placement.syllables.keys.sort.flat_map do |verse|
        syllable = placement.syllables[verse]
        [
          %(#{INDENT * 4}<lyric number="#{verse}">),
          "#{INDENT * 5}<syllabic>#{syllabic(placement, syllable)}</syllabic>",
          "#{INDENT * 5}<text>#{escape(syllable.text)}</text>",
          "#{INDENT * 4}</lyric>"
        ]
      end
    end

    # Derives MusicXML's single/begin/middle/end from our stored hyphen_after
    # booleans: this syllable's, and the previous sung note's for the same verse.
    def syllabic(placement, syllable)
      from_previous = previous_syllable(placement, syllable.verse)&.hyphen_after?
      if from_previous
        syllable.hyphen_after? ? "middle" : "end"
      else
        syllable.hyphen_after? ? "begin" : "single"
      end
    end

    # The syllable on the nearest earlier placement in the same voice carrying
    # text for this verse. Placements are position-sorted, and melisma gaps are
    # skipped because only sung placements are collected.
    def previous_syllable(placement, verse)
      @sung_placements ||= {}
      sung = @sung_placements[[placement.voice, verse]] ||=
        placement.voice.placements.select { |candidate| candidate.syllable(verse) }
      index = sung.index(placement)
      return nil if index.nil? || index.zero?

      sung[index - 1].syllable(verse)
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
