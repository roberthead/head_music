require "spec_helper"

describe HeadMusic::Instruments::StringingCourse do
  describe "initialization" do
    context "with a single string" do
      subject(:course) { described_class.new(standard_pitch: "E2") }

      it "sets the standard pitch" do
        expect(course.standard_pitch).to eq HeadMusic::Rudiment::Pitch.get("E2")
      end

      it "has empty course_semitones" do
        expect(course.course_semitones).to eq []
      end

      it "has one string" do
        expect(course.string_count).to eq 1
      end

      it "is not doubled" do
        expect(course).not_to be_doubled
      end

      it "returns only the standard pitch" do
        expect(course.pitches).to eq [HeadMusic::Rudiment::Pitch.get("E2")]
      end
    end

    context "with a doubled string at octave" do
      subject(:course) { described_class.new(standard_pitch: "E2", course_semitones: [12]) }

      it "has two strings" do
        expect(course.string_count).to eq 2
      end

      it "is doubled" do
        expect(course).to be_doubled
      end

      it "returns both pitches" do
        pitches = course.pitches
        expect(pitches.length).to eq 2
        expect(pitches[0]).to eq HeadMusic::Rudiment::Pitch.get("E2")
        expect(pitches[1]).to eq HeadMusic::Rudiment::Pitch.get("E3")
      end
    end

    context "with a doubled string in unison" do
      subject(:course) { described_class.new(standard_pitch: "B3", course_semitones: [0]) }

      it "has two strings" do
        expect(course.string_count).to eq 2
      end

      it "is doubled" do
        expect(course).to be_doubled
      end

      it "returns both pitches at the same frequency" do
        pitches = course.pitches
        expect(pitches.length).to eq 2
        expect(pitches[0]).to eq HeadMusic::Rudiment::Pitch.get("B3")
        expect(pitches[1]).to eq HeadMusic::Rudiment::Pitch.get("B3")
      end
    end
  end

  describe "#==" do
    let(:course1) { described_class.new(standard_pitch: "E2") }
    let(:course1_copy) { described_class.new(standard_pitch: "E2") }
    let(:course2) { described_class.new(standard_pitch: "A2") }
    let(:course3) { described_class.new(standard_pitch: "E2", course_semitones: [12]) }

    it "compares by pitch and course_semitones" do
      expect(course1).to eq course1_copy
      expect(course1).not_to eq course2
      expect(course1).not_to eq course3
    end

    it "returns false when compared with non-StringingCourse" do
      expect(course1).not_to eq "E2"
    end
  end

  describe "#to_s" do
    subject { described_class.new(standard_pitch: "G3") }

    its(:to_s) { is_expected.to eq "G3" }
  end
end
