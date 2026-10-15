module HeadMusic::Notation::MEI
  # The opening <scoreDef>: key, meter, and tempo, and a <staffDef> for every
  # staff of the score.
  class ScoreDefWriter
    CLEF_REGISTERS = {"G" => 4, "F" => 3, "C" => 4}.freeze
    DISPLACEMENTS = {1 => "8", 2 => "15", 3 => "22"}.freeze

    # A neutral clef has no pitch.
    def self.clef_attributes(clef)
      return {"shape" => "perc"} unless clef.pitch

      letter = clef.pitch.letter_name.to_s
      octaves = clef.pitch.register - CLEF_REGISTERS.fetch(letter)
      {
        "shape" => letter,
        "line" => clef.line,
        "dis" => DISPLACEMENTS[octaves.abs],
        "dis.place" => if octaves.zero?
                         nil
                       else
                         (octaves.positive? ? "above" : "below")
                       end
      }
    end

    def initialize(plan)
      @plan = plan
    end

    def element
      Element.new("scoreDef", ids.container("scoredef"), score_def_attributes, [staff_group_element])
    end

    private

    attr_reader :plan

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
        "meter.count" => meter.top_number,
        "meter.unit" => meter.bottom_number,
        "midi.bpm" => plan.midi_bpm(plan.flow.tempo_at(first_bar))
      }
    end

    def staff_group_element
      Element.new("staffGrp", ids.container("staffgrp"), {}, plan.staff_entries.map { |entry| staff_def_element(entry) })
    end

    def staff_def_element(entry)
      id = ids.container("staffdef", "s#{entry.number}")
      attributes = {"n" => entry.number, "lines" => entry.staff.line_count}
      Element.new("staffDef", id, attributes, [clef_element(entry)])
    end

    def clef_element(entry)
      Element.new("clef", ids.container("clef", "s#{entry.number}"), self.class.clef_attributes(clef(entry)))
    end

    def clef(entry)
      voice = plan.layer_voices(entry, first_bar).first || entry.part.voices.first
      entry.staff.clef_at(first_bar) || HeadMusic::Notation::ClefSelector.for(voice)
    end
  end
end
