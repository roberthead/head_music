require "spec_helper"

describe HeadMusic::Notation::Kern::SpineLayout do
  def record(fields, kind: :interpretation, line: 5)
    HeadMusic::Notation::Kern::Record.new(kind: kind, line: line, fields: fields)
  end

  def layout(*exclusives)
    described_class.new(record(exclusives, kind: :exclusive, line: 1))
  end

  describe "tracks" do
    subject(:tracks) { layout("**kern", "**text", "**silbe", "**dynam").tracks }

    it "classifies each spine" do
      expect(tracks.map(&:kind)).to eq %i[kern lyric lyric skipped]
    end

    it "remembers the header column each track came from" do
      expect(tracks.map(&:origin)).to eq [0, 1, 2, 3]
    end
  end

  describe "#apply" do
    it "splits a track, keeping the left half as the original" do
      spines = layout("**kern", "**kern")
      original = spines.tracks.first
      manipulations = spines.apply(record(%w[*^ *]))
      expect([spines.tracks.length, spines.tracks.first, manipulations.map(&:type)]).to eq [3, original, [:split]]
    end

    it "gives the right half of a split the same origin" do
      spines = layout("**kern")
      spines.apply(record(%w[*^]))
      expect(spines.tracks.map(&:origin)).to eq [0, 0]
    end

    it "joins adjacent tracks into their leftmost" do
      spines = layout("**kern", "**kern", "**kern")
      left, middle, right = spines.tracks
      manipulations = spines.apply(record(%w[*v *v *]))
      expect([spines.tracks, manipulations.first.tracks]).to eq [[left, right], [left, middle]]
    end

    it "joins every track in a run of *v" do
      spines = layout("**kern", "**kern", "**kern")
      spines.apply(record(%w[*v *v *v]))
      expect(spines.tracks.length).to eq 1
    end

    it "exchanges a pair of tracks" do
      spines = layout("**kern", "**dynam")
      kern, dynam = spines.tracks
      spines.apply(record(%w[*x *x]))
      expect(spines.tracks).to eq [dynam, kern]
    end

    it "ends a track" do
      spines = layout("**kern", "**kern")
      kept = spines.tracks.last
      manipulations = spines.apply(record(%w[*- *]))
      expect([spines.tracks, manipulations.map(&:type)]).to eq [[kept], [:end]]
    end

    it "tracks manipulators in skipped spines" do
      spines = layout("**kern", "**dynam")
      spines.apply(record(%w[* *^]))
      expect(spines.tracks.map(&:kind)).to eq %i[kern skipped skipped]
    end

    it "raises for a lone *v" do
      expect { layout("**kern", "**kern").apply(record(%w[*v *])) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /\*v must join two or more adjacent spines \(line 5\)/)
    end

    it "raises for a join of non-adjacent spines" do
      expect { layout("**kern", "**kern", "**kern").apply(record(%w[*v * *v])) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /adjacent spines/)
    end

    it "raises for a join of spines of different kinds" do
      expect { layout("**kern", "**dynam").apply(record(%w[*v *v])) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /different kinds/)
    end

    it "raises for an unpaired *x" do
      expect { layout("**kern", "**kern").apply(record(%w[*x *])) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /exactly two adjacent spines \(line 5\)/)
    end

    it "raises for three *x in a row" do
      expect { layout("**kern", "**kern", "**kern").apply(record(%w[*x *x *x])) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /exactly two/)
    end

    it "raises an unsupported-feature error for a split in a lyric spine" do
      expect { layout("**kern", "**text").apply(record(%w[* *^])) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Splitting a \*\*text spine/)
    end

    it "raises an unsupported-feature error for *+" do
      expect { layout("**kern").apply(record(%w[*+])) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /\*\+ is not supported \(line 5\)/)
    end
  end

  describe "#ensure_width" do
    it "raises when a row's field count does not match the live spines" do
      expect { layout("**kern", "**kern").ensure_width(record(%w[4c], kind: :data)) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Row has 1 field but 2 spines are live \(line 5\)/)
    end
  end

  describe ".manipulator_row?" do
    it "recognizes a row with a manipulator" do
      expect(described_class.manipulator_row?(record(%w[* *^]))).to be true
    end

    it "does not count other interpretations" do
      expect(described_class.manipulator_row?(record(%w[*M4/4 *k[]]))).to be false
    end
  end
end
