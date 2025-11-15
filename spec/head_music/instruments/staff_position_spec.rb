require "spec_helper"

describe HeadMusic::Instruments::StaffPosition do
  describe ".name_to_index" do
    context "with exact case matching" do
      it "returns the index for 'bottom line'" do
        expect(described_class.name_to_index("bottom line")).to eq(0)
      end

      it "returns the index for 'middle line'" do
        expect(described_class.name_to_index("middle line")).to eq(4)
      end

      it "returns the index for 'top line'" do
        expect(described_class.name_to_index("top line")).to eq(8)
      end

      it "returns the index for 'space below staff'" do
        expect(described_class.name_to_index("space below staff")).to eq(-1)
      end

      it "returns the index for 'ledger line above staff'" do
        expect(described_class.name_to_index("ledger line above staff")).to eq(10)
      end
    end

    context "with alternate names" do
      it "returns the index for 'line 1'" do
        expect(described_class.name_to_index("line 1")).to eq(0)
      end

      it "returns the index for 'line 3'" do
        expect(described_class.name_to_index("line 3")).to eq(4)
      end

      it "returns the index for 'bottom space'" do
        expect(described_class.name_to_index("bottom space")).to eq(1)
      end

      it "returns the index for 'space 1'" do
        expect(described_class.name_to_index("space 1")).to eq(1)
      end
    end

    context "with case variations" do
      it "is case insensitive with uppercase" do
        expect(described_class.name_to_index("MIDDLE LINE")).to eq(4)
      end

      it "is case insensitive with mixed case" do
        expect(described_class.name_to_index("Middle Line")).to eq(4)
      end

      it "is case insensitive with lowercase" do
        expect(described_class.name_to_index("bottom line")).to eq(0)
      end

      it "is case insensitive with all uppercase" do
        expect(described_class.name_to_index("TOP LINE")).to eq(8)
      end

      it "is case insensitive with alternate names" do
        expect(described_class.name_to_index("LINE 3")).to eq(4)
      end
    end

    context "with symbol inputs" do
      it "accepts symbols for exact matches in NAMES" do
        expect(described_class.name_to_index(:"middle line")).to eq(4)
      end

      it "accepts symbols with case variations" do
        expect(described_class.name_to_index(:"Middle Line")).to eq(4)
      end

      it "accepts symbols for all uppercase" do
        expect(described_class.name_to_index(:"TOP LINE")).to eq(8)
      end

      it "accepts symbols for alternate names" do
        expect(described_class.name_to_index(:"line 1")).to eq(0)
      end
    end

    context "with invalid inputs" do
      it "returns nil for non-existent position name" do
        expect(described_class.name_to_index("invalid position")).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.name_to_index("")).to be_nil
      end

      it "returns nil for nonsense input" do
        expect(described_class.name_to_index("foobar")).to be_nil
      end
    end

    context "with all defined positions" do
      it "returns -2 for ledger line below staff" do
        expect(described_class.name_to_index("ledger line below staff")).to eq(-2)
      end

      it "returns -1 for space below staff" do
        expect(described_class.name_to_index("space below staff")).to eq(-1)
      end

      it "returns 0 for bottom line" do
        expect(described_class.name_to_index("bottom line")).to eq(0)
      end

      it "returns 1 for bottom space" do
        expect(described_class.name_to_index("bottom space")).to eq(1)
      end

      it "returns 2 for line 2" do
        expect(described_class.name_to_index("line 2")).to eq(2)
      end

      it "returns 3 for space 2" do
        expect(described_class.name_to_index("space 2")).to eq(3)
      end

      it "returns 4 for middle line" do
        expect(described_class.name_to_index("middle line")).to eq(4)
      end

      it "returns 5 for space 3" do
        expect(described_class.name_to_index("space 3")).to eq(5)
      end

      it "returns 6 for line 4" do
        expect(described_class.name_to_index("line 4")).to eq(6)
      end

      it "returns 7 for space 4" do
        expect(described_class.name_to_index("space 4")).to eq(7)
      end

      it "returns 8 for top line" do
        expect(described_class.name_to_index("top line")).to eq(8)
      end

      it "returns 9 for space above staff" do
        expect(described_class.name_to_index("space above staff")).to eq(9)
      end

      it "returns 10 for ledger line above staff" do
        expect(described_class.name_to_index("ledger line above staff")).to eq(10)
      end
    end
  end

  describe "#initialize" do
    it "accepts an index" do
      position = described_class.new(4)
      expect(position.index).to eq(4)
    end
  end

  describe "#line?" do
    it "returns true for even indices" do
      expect(described_class.new(0)).to be_line
      expect(described_class.new(2)).to be_line
      expect(described_class.new(4)).to be_line
    end

    it "returns false for odd indices" do
      expect(described_class.new(1)).not_to be_line
      expect(described_class.new(3)).not_to be_line
      expect(described_class.new(5)).not_to be_line
    end
  end

  describe "#space?" do
    it "returns true for odd indices" do
      expect(described_class.new(1)).to be_space
      expect(described_class.new(3)).to be_space
      expect(described_class.new(5)).to be_space
    end

    it "returns false for even indices" do
      expect(described_class.new(0)).not_to be_space
      expect(described_class.new(2)).not_to be_space
      expect(described_class.new(4)).not_to be_space
    end
  end

  describe "#line_number" do
    it "returns the line number for lines" do
      expect(described_class.new(0).line_number).to eq(1)
      expect(described_class.new(2).line_number).to eq(2)
      expect(described_class.new(4).line_number).to eq(3)
      expect(described_class.new(6).line_number).to eq(4)
      expect(described_class.new(8).line_number).to eq(5)
    end

    it "returns nil for spaces" do
      expect(described_class.new(1).line_number).to be_nil
      expect(described_class.new(3).line_number).to be_nil
    end
  end

  describe "#space_number" do
    it "returns the space number for spaces" do
      expect(described_class.new(1).space_number).to eq(1)
      expect(described_class.new(3).space_number).to eq(2)
      expect(described_class.new(5).space_number).to eq(3)
      expect(described_class.new(7).space_number).to eq(4)
    end

    it "returns nil for lines" do
      expect(described_class.new(0).space_number).to be_nil
      expect(described_class.new(2).space_number).to be_nil
    end
  end

  describe "#to_s" do
    context "with named positions in NAMES dictionary" do
      it "returns the first name for bottom line" do
        expect(described_class.new(0).to_s).to eq("bottom line")
      end

      it "returns the first name for middle line" do
        expect(described_class.new(4).to_s).to eq("middle line")
      end

      it "returns the first name for top line" do
        expect(described_class.new(8).to_s).to eq("top line")
      end

      it "returns the first name for space below staff" do
        expect(described_class.new(-1).to_s).to eq("space below staff")
      end

      it "returns the first name for ledger line above staff" do
        expect(described_class.new(10).to_s).to eq("ledger line above staff")
      end
    end

    context "with positions not in NAMES dictionary" do
      it "returns calculated line name for line positions" do
        expect(described_class.new(10).to_s).to eq("ledger line above staff")
      end

      it "returns calculated space name for space positions" do
        expect(described_class.new(11).space_number).to eq(6)
      end
    end

    describe "fallback behavior for undefined positions" do
      it "falls back to 'line N' format for unmapped lines" do
        position = described_class.new(12)
        expect(position.to_s).to eq("line 7")
      end

      it "falls back to 'space N' format for unmapped spaces" do
        position = described_class.new(13)
        expect(position.to_s).to eq("space 7")
      end
    end
  end
end
