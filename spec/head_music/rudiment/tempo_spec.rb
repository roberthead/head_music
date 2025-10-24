require "spec_helper"

describe HeadMusic::Rudiment::Tempo do
  describe ".get" do
    subject(:tempo) { described_class.get(identifier) }

    context "with numeric tempo markings" do
      context "with q = 120" do
        let(:identifier) { "q = 120" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 120 }
      end

      context "with q at 120bpm" do
        let(:identifier) { "q at 120bpm" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 120 }
      end

      context "with h = 80" do
        let(:identifier) { "h = 80" }

        its(:beat_value) { is_expected.to eq "half" }
        its(:beats_per_minute) { is_expected.to eq 80 }
      end

      context "with e at 200bpm" do
        let(:identifier) { "e at 200bpm" }

        its(:beat_value) { is_expected.to eq "eighth" }
        its(:beats_per_minute) { is_expected.to eq 200 }
      end

      context "with 1/4 = 96" do
        let(:identifier) { "1/4 = 96" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 96 }
      end

      context "with crotchet = 108" do
        let(:identifier) { "crotchet = 108" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 108 }
      end
    end

    context "with named tempo markings" do
      context "with very slow tempos" do
        context "with larghissimo" do
          let(:identifier) { :larghissimo }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 24 }
        end

        context "with grave" do
          let(:identifier) { "grave" }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 32 }
        end

        context "with largo" do
          let(:identifier) { :largo }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 54 }
        end
      end

      context "with slow tempos" do
        context "with adagio" do
          let(:identifier) { :adagio }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 60 }
        end

        context "with lento" do
          let(:identifier) { "lento" }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 72 }
        end
      end

      context "with moderate tempos" do
        context "with andante" do
          let(:identifier) { :andante }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 78 }
        end

        context "with moderato" do
          let(:identifier) { :moderato }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 108 }
        end
      end

      context "with fast tempos" do
        context "with allegro" do
          let(:identifier) { :allegro }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 120 }
        end

        context "with vivace" do
          let(:identifier) { :vivace }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 156 }
        end
      end

      context "with very fast tempos" do
        context "with presto" do
          let(:identifier) { :presto }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 180 }
        end

        context "with prestissimo" do
          let(:identifier) { :prestissimo }

          its(:beat_value) { is_expected.to eq "quarter" }
          its(:beats_per_minute) { is_expected.to eq 200 }
        end
      end
    end

    context "with unknown identifier" do
      let(:identifier) { "unknown_tempo" }

      its(:beat_value) { is_expected.to eq "quarter" }
      its(:beats_per_minute) { is_expected.to eq 120 }
    end

    context "with edge cases" do
      context "with whitespace around equals sign" do
        let(:identifier) { "q  =  120" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 120 }
      end

      context "with extra text after bpm" do
        let(:identifier) { "q = 120bpm (fast)" }

        its(:beat_value) { is_expected.to eq "quarter" }
        its(:beats_per_minute) { is_expected.to eq 120 }
      end
    end

    describe "caching behavior" do
      it "returns the same object for the same identifier" do
        tempo1 = described_class.get("q = 120")
        tempo2 = described_class.get("q = 120")
        expect(tempo1).to be(tempo2)
      end

      it "returns the same object for equivalent named tempos" do
        tempo1 = described_class.get(:allegro)
        tempo2 = described_class.get("allegro")
        expect(tempo1).to be(tempo2)
      end
    end
  end

  describe ".standardized_unit" do
    context "with abbreviations" do
      it "converts q to quarter" do
        expect(described_class.standardized_unit("q")).to eq "quarter"
      end

      it "converts h to half" do
        expect(described_class.standardized_unit("h")).to eq "half"
      end

      it "converts e to eighth" do
        expect(described_class.standardized_unit("e")).to eq "eighth"
      end

      it "converts s to sixteenth" do
        expect(described_class.standardized_unit("s")).to eq "sixteenth"
      end
    end

    context "with fraction notation" do
      it "converts 1/4 to quarter" do
        expect(described_class.standardized_unit("1/4")).to eq "quarter"
      end

      it "converts 1/2 to half" do
        expect(described_class.standardized_unit("1/2")).to eq "half"
      end

      it "converts 1/8 to eighth" do
        expect(described_class.standardized_unit("1/8")).to eq "eighth"
      end

      it "converts 1/16 to sixteenth" do
        expect(described_class.standardized_unit("1/16")).to eq "sixteenth"
      end
    end

    context "with British note names" do
      it "converts crotchet to quarter" do
        expect(described_class.standardized_unit("crotchet")).to eq "quarter"
      end

      it "converts minim to half" do
        expect(described_class.standardized_unit("minim")).to eq "half"
      end

      it "converts quaver to eighth" do
        expect(described_class.standardized_unit("quaver")).to eq "eighth"
      end

      it "converts semiquaver to sixteenth" do
        expect(described_class.standardized_unit("semiquaver")).to eq "sixteenth"
      end
    end

    context "with case variations" do
      it "handles uppercase Q" do
        expect(described_class.standardized_unit("Q")).to eq "quarter"
      end

      it "handles mixed case Crotchet" do
        expect(described_class.standardized_unit("Crotchet")).to eq "quarter"
      end
    end

    context "with whitespace" do
      it "handles leading and trailing whitespace" do
        expect(described_class.standardized_unit("  q  ")).to eq "quarter"
      end
    end

    context "with unknown units" do
      it "defaults to quarter" do
        expect(described_class.standardized_unit("unknown")).to eq "quarter"
      end

      it "defaults to quarter for nil" do
        expect(described_class.standardized_unit(nil)).to eq "quarter"
      end
    end

    context "with RhythmicUnit::Parser integration" do
      it "uses parser for dotted notes" do
        result = described_class.standardized_unit("q.")
        expect(result).to eq "dotted quarter"
      end

      it "uses parser for double dotted notes" do
        result = described_class.standardized_unit("q..")
        expect(result).to eq "double-dotted quarter"
      end

      it "uses parser for full note names" do
        result = described_class.standardized_unit("quarter")
        expect(result).to eq "quarter"
      end
    end
  end

  describe "#initialize" do
    subject(:tempo) { described_class.new(beat_value, beats_per_minute) }

    context "with q = 120" do
      let(:beat_value) { "quarter" }
      let(:beats_per_minute) { 120 }

      its(:beat_value) { is_expected.to eq "quarter" }
      its(:beats_per_minute) { is_expected.to eq 120 }
      its(:beat_duration_in_seconds) { is_expected.to eq 0.5 }
      its(:beat_duration_in_nanoseconds) { is_expected.to eq 500_000_000 }
      its(:tick_duration_in_nanoseconds) { is_expected.to be_within(0.01).of(520_833.33) }
      its(:ticks_per_beat) { is_expected.to eq 960 }
    end

    context "with e = 140" do
      let(:beat_value) { "eighth" }
      let(:beats_per_minute) { 140 }

      its(:beat_value) { is_expected.to eq "eighth" }
      its(:beats_per_minute) { is_expected.to eq 140 }
      its(:beat_duration_in_seconds) { is_expected.to be_within(0.00001).of(0.42857) }
      its(:beat_duration_in_nanoseconds) { is_expected.to be_within(1).of(428571428) }
      its(:tick_duration_in_nanoseconds) { is_expected.to be_within(0.01).of(892_857.14) }
      its(:ticks_per_beat) { is_expected.to eq 480 }
    end

    context "with q. = 92" do
      let(:beat_value) { "dotted quarter" }
      let(:beats_per_minute) { 92 }

      its(:beat_value) { is_expected.to eq "dotted quarter" }
      its(:beats_per_minute) { is_expected.to eq 92 }
      its(:beat_duration_in_seconds) { is_expected.to eq(0.6521739130434783) }
      its(:beat_duration_in_nanoseconds) { is_expected.to be_within(1).of(652173913) }
      its(:tick_duration_in_nanoseconds) { is_expected.to be_within(0.01).of(452_898.55) }
      its(:ticks_per_beat) { is_expected.to eq 1440 }
    end

    context "with h = 60" do
      let(:beat_value) { "half" }
      let(:beats_per_minute) { 60 }

      its(:beat_value) { is_expected.to eq "half" }
      its(:beats_per_minute) { is_expected.to eq 60 }
      its(:beat_duration_in_seconds) { is_expected.to eq 1.0 }
      its(:beat_duration_in_nanoseconds) { is_expected.to eq 1_000_000_000 }
      its(:ticks_per_beat) { is_expected.to eq 1920 }
    end

    context "with integer beats_per_minute" do
      let(:beat_value) { "quarter" }
      let(:beats_per_minute) { 100 }

      it "converts to float" do
        expect(tempo.beats_per_minute).to eq 100.0
        expect(tempo.beats_per_minute).to be_a(Float)
      end
    end

    context "with string beats_per_minute" do
      let(:beat_value) { "quarter" }
      let(:beats_per_minute) { "100" }

      it "converts to float" do
        expect(tempo.beats_per_minute).to eq 100.0
        expect(tempo.beats_per_minute).to be_a(Float)
      end
    end
  end
end
