require "spec_helper"

describe HeadMusic::Style::Guide do
  describe "grading a flow with markings" do
    def grades(flow)
      described_class::ALL.flat_map do |guide|
        flow.voices.map do |voice|
          assessment = guide.assess(voice)
          items = assessment.assessments.flat_map(&:guide_item_assessments)
          [assessment.fitness, items.map { |item| [item.name, item.fitness, item.marks.map { |mark| [mark.code, mark.fitness] }] }]
        end
      end
    end

    def example_flow
      fux_first_species_examples.first.flow
    end

    let(:plain) { example_flow }

    let(:marked) do
      example_flow.tap do |flow|
        cantus_firmus, counterpoint = flow.voices
        notes = counterpoint.note_events
        notes[0].articulate(:staccato, :accent)
        notes[1].embellish(:trill)
        notes[2].note_dynamic = :sfz
        cantus_firmus.note_events[3].note_dynamic = :fp
        counterpoint.place_dynamic("1:1", :p)
        counterpoint.place_dynamic("3:3", :f)
        cantus_firmus.part.place_dynamic("5:1", :mf)
        counterpoint.add_span(:phrase, from: "1:1", to: "5:1")
        counterpoint.add_span(:slur, from: "2:1", to: "4:1")
        cantus_firmus.add_span(:slur, from: "1:1", to: "3:1")
      end
    end

    it "has marks to compare" do
      expect(grades(plain).flat_map(&:last).flat_map(&:last)).not_to be_empty
    end

    it "gives the same fitness and marks as without them, spans included" do
      expect(grades(marked)).to eq grades(plain)
    end
  end
end
