require "spec_helper"

describe HeadMusic::Notation::MusicXML::DirectionMarks do
  subject(:direction_marks) { described_class.new(piano, plan) }

  let(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }
  let(:flow) do
    HeadMusic::Content::Flow.new(name: "Marks", meter: "4/4").tap do |flow|
      piano = flow.add_part(instrument: "piano", staff_system: HeadMusic::Content::StaffSystem.grand_staff)
      right_hand = piano.add_voice(role: "right hand")
      left_hand = piano.add_voice(role: "left hand")
      right_hand.place("1:1", :whole, "E4")
      right_hand.place("2:1", :whole, "G4")
      left_hand.place("1:1", :whole, "C3")
      left_hand.place("2:1", :whole, "C3")
      right_hand.place_dynamic("2:1", :f)
      right_hand.add_span(:crescendo, from: "1:3", to: "2:1")
      right_hand.add_span(:diminuendo, from: "2:1", to: "2:3")
      left_hand.place_dynamic("1:1", :p)
      piano.place_dynamic("1:1", :mf)
      flow.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 90))
    end
  end
  let(:piano) { flow.parts.first }

  def described(marks)
    marks.map { |mark| [mark.type, mark.position.to_s] }
  end

  describe "#by_owner" do
    it "lists the part, then each of its voices" do
      expect(direction_marks.by_owner.map(&:first)).to eq [piano, *piano.voices]
    end

    it "gives the part its own dynamics" do
      expect(described(direction_marks.by_owner.first.last)).to eq [[:dynamic, "1:1:000"]]
    end

    it "orders a position's tempo, hairpin stop, dynamic, then hairpin start" do
      expect(described(direction_marks.by_owner[1].last)).to eq [
        [:start, "1:3:000"], [:tempo, "2:1:000"], [:stop, "2:1:000"], [:dynamic, "2:1:000"], [:start, "2:1:000"], [:stop, "2:3:000"]
      ]
    end

    it "gives the tempo marks to the first voice alone" do
      expect(described(direction_marks.by_owner.last.last)).to eq [[:dynamic, "1:1:000"]]
    end

    context "with a second part" do
      subject(:direction_marks) { described_class.new(flow.parts.last, plan) }

      before do
        flow.add_part(instrument: "violin").add_voice.place("1:1", :whole, "A4")
      end

      it "writes no tempo marks" do
        expect(direction_marks.by_owner.flat_map(&:last)).to be_empty
      end
    end
  end

  describe "Mark#label" do
    it "names a dynamic and a hairpin's start and end" do
      dynamic = HeadMusic::Rudiment::Dynamic.get(:p)
      hairpin = HeadMusic::Rudiment::SpanKind.get(:crescendo)
      labels = [[:dynamic, dynamic], [:start, hairpin], [:stop, hairpin]].map { |type, item| described_class::Mark.new(type, nil, item).label }
      expect(labels).to eq ["dynamic p", "crescendo start", "crescendo end"]
    end

    it "names a tempo mark by its kind" do
      kinds = %i[tempo ramp_start ramp_end a_tempo]
      labels = kinds.map { |kind| described_class::Mark.new(:tempo, nil, HeadMusic::Notation::TempoMarks::Mark.new(kind, nil, nil, nil)).label }
      expect(labels).to eq ["tempo change", "tempo ramp start", "tempo ramp end", %("a tempo")]
    end
  end
end
