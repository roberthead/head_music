require "spec_helper"

describe HeadMusic::Style::Guidelines::ConsonantClimax do
  subject { assess(described_class, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with an ascending melody" do
    context "when the high note occurs once" do
      context "when on the 3rd scale degree" do
        before do
          %w[C D E D C G3 A3 D C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        it { is_expected.to be_adherent }
      end

      context "when on the 7th scale degree" do
        before do
          %w[C D E G B G F E D C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be < 1 }
      end
    end

    context "when the high note occurs twice" do
      context "when on the 3rd scale degree" do
        context "with one step between" do
          before do
            %w[C D E D E C G3 A3 D C].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          it { is_expected.to be_adherent }
        end

        context "with one skip between" do
          before do
            %w[C D E C E C G3 A3 B3 C].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
        end

        context "with more than one note between" do
          before do
            %w[C D E D C E D G3 A3 D C].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
        end
      end

      context "when on the 7th scale degree" do
        before do
          %w[C D E G B A B G E D C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
      end
    end

    context "when the high note occurs three times" do
      before do
        %w[C D E D C E D E D G3 A3 D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
    end
  end

  context "with a descending melody" do
    context "when the low note occurs once" do
      context "when on the 3rd scale degree" do
        before do
          %w[C4 B3 G3 A3 F3 E3 G3 B3 C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        it { is_expected.to be_adherent }
      end

      context "when on the 2nd scale degree" do
        before do
          %w[C4 B3 G3 D3 E3 G3 B3 C4].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be < 1 }
      end
    end

    context "when the low note occurs twice" do
      context "when on the 3rd scale degree" do
        context "with one step between" do
          before do
            %w[C4 B3 G3 A3 F3 E3 F3 E3 G3 B3 C].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          it { is_expected.to be_adherent }
        end

        context "with one skip between" do
          before do
            %w[C4 G3 A3 F3 E3 G3 E3 F3 G3 B3 C4].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
        end

        context "with more than one note between" do
          before do
            %w[C4 B3 G3 A3 F3 E3 F3 G3 F3 E3 G3 B3 C].each.with_index(1) do |pitch, bar|
              voice.place("#{bar}:1", :whole, pitch)
            end
          end

          its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
        end
      end
    end
  end

  # Salzer and Schachter: "The high point of a line should never be repeated"
  # (p. 8), and in the moving species "the climax itself should not be
  # repeated" (p. 42). No species-tradition source clears either shape.
  context "with Fux's liberties at the climax" do
    def climax_marks(figure)
      assess(described_class, fux_fifth_species_example(figure).counterpoint_voice).marks.map(&:code)
    end

    it "marks figure 84a, whose phrygian line opens and closes on its peak" do
      expect(climax_marks("84a")).to eq ["1:3:000 to 2:2:000", "8:3:000 to 9:3:000", "10:1:000 to 11:1:000"]
    end

    it "marks figure 87 upper, whose peak is re-approached by leap within one bar" do
      expect(climax_marks("87 upper counterpoint (scan only; no kern transcription)"))
        .to eq ["7:1:000 to 7:2:000", "7:3:000 to 8:2:000"]
    end
  end
end
