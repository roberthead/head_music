module HeadMusic::Notation::MEI
  # The opening <scoreDef>: key, meter, and tempo, and a <staffDef> for every
  # staff of the score, those of a part on several staves in a <staffGrp> of
  # their own.
  #
  # Extension classes registered in staff_def_attribute_sources are built
  # once per plan with .new(plan) and answer #staff_def_attributes(entry), a
  # Hash merged into the opening staffDef of that StaffNumbering::Entry.
  class ScoreDefWriter
    CLEF_REGISTERS = {"G" => 4, "F" => 3, "C" => 4}.freeze
    DISPLACEMENTS = {1 => "8", 2 => "15", 3 => "22"}.freeze
    PLACES = {1 => "above", -1 => "below"}.freeze

    def self.staff_def_attribute_sources
      @staff_def_attribute_sources ||= []
    end

    # A neutral clef has no pitch.
    def self.clef_attributes(clef)
      return {"shape" => "perc"} unless clef.pitch

      pitch = clef.pitch
      letter = pitch.letter_name.to_s
      octaves = pitch.register - CLEF_REGISTERS.fetch(letter)
      {"shape" => letter, "line" => clef.line, "dis" => DISPLACEMENTS[octaves.abs], "dis.place" => PLACES[octaves <=> 0]}
    end

    # Nil for no instrument. The label is the instrument's name key, since
    # several instruments share a General MIDI program, which is numbered from
    # 1 where MEI numbers from 0.
    def self.instr_def_attributes(instrument)
      return unless instrument

      program = instrument.gm_program
      {"label" => instrument.name_key.to_s, "midi.instrnum" => program && (program - 1)}
    end

    # A staff definition's <clef>, keyed as it is, or nil for no clef.
    def self.clef_element(ids, key, clef)
      clef && Element.new("clef", ids.container("clef", key), clef_attributes(clef))
    end

    # A staff definition's <instrDef>, keyed as it is, or nil for no
    # instrument.
    def self.instr_def_element(ids, key, instrument)
      attributes = instr_def_attributes(instrument)
      attributes && Element.new("instrDef", ids.container("instrdef", key), attributes)
    end

    def initialize(plan)
      @plan = plan
      @attribute_sources = self.class.staff_def_attribute_sources.map { |source_class| plan.source(source_class) }
    end

    def element
      Element.new("scoreDef", ids.container("scoredef"), score_def_attributes, [staff_group_element])
    end

    private

    attr_reader :plan, :attribute_sources

    def ids
      plan.ids
    end

    def first_bar
      plan.bar_numbers.first
    end

    def score_def_attributes
      meter = plan.first_measure_meter
      {
        "keysig" => plan.first_measure_key,
        "key.mode" => plan.first_measure_key_mode,
        "meter.count" => meter.top_number,
        "meter.unit" => meter.bottom_number,
        "midi.bpm" => plan.midi_bpm(plan.flow.tempo_at(first_bar))
      }
    end

    def staff_group_element
      Element.new("staffGrp", ids.container("staffgrp"), {}, plan.flow.parts.map { |part| part_element(part) })
    end

    # The label is the player's alone, since a reader turns it back into one.
    def part_element(part)
      entries = plan.staff_entries_of(part)
      player = part.player
      label = player && label_element(part_key(part), player.name)
      return staff_def_element(entries.first, label) if entries.one?

      symbol = part.staff_system.bracket
      Element.new(
        "staffGrp", ids.container("staffgrp", part_key(part)), {"symbol" => (symbol == :none) ? nil : symbol.to_s},
        [label, *entries.map { |entry| staff_def_element(entry, nil) }].compact
      )
    end

    def staff_def_element(entry, label)
      key = "s#{entry.number}"
      attributes = attribute_sources.reduce({"n" => entry.number, "lines" => entry.staff.line_count}) do |merged, source|
        merged.merge(source.staff_def_attributes(entry))
      end
      children = [
        label, self.class.clef_element(ids, key, clef(entry)),
        self.class.instr_def_element(ids, key, entry.part.instrument_at(first_bar)), *layer_def_elements(entry)
      ].compact
      Element.new("staffDef", ids.container("staffdef", key), attributes, children)
    end

    def clef(entry)
      voice = plan.layer_voices(entry, first_bar).first || entry.part.voices.first
      entry.staff.clef_at(first_bar) || HeadMusic::Notation::ClefSelector.for(voice)
    end

    # On the staff each voice opens on, for each voice with a role.
    def layer_def_elements(entry)
      plan.layer_voices(entry, first_bar).filter_map do |voice|
        role = voice.role.to_s
        next if role.strip.empty?

        number = plan.voice_number(voice)
        key = ids.owner_key(entry.part_number, number)
        Element.new("layerDef", ids.container("layerdef", key), {"n" => number}, [label_element(key, role)])
      end
    end

    def label_element(key, text)
      Element.new("label", ids.container("label", key), {}, [], text)
    end

    def part_key(part)
      ids.owner_key(plan.part_number(part))
    end
  end
end
