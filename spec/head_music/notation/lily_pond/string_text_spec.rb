require "spec_helper"

describe HeadMusic::Notation::LilyPond::StringText do
  describe ".escape" do
    it "escapes double quotes" do
      expect(described_class.escape(%(the "Great" tune))).to eq %(the \\"Great\\" tune)
    end

    it "doubles backslashes before escaping quotes, so a backslash cannot re-open the string" do
      expect(described_class.escape(%(a \\ b))).to eq %(a \\\\ b)
    end

    it "escapes a backslash-quote sequence safely" do
      expect(described_class.escape(%(\\"))).to eq %(\\\\\\")
    end

    it "coerces non-strings" do
      expect(described_class.escape(nil)).to eq ""
    end
  end

  describe ".unescape" do
    it "reads escaped quotes back" do
      expect(described_class.unescape(%(the \\"Great\\" tune))).to eq %(the "Great" tune)
    end

    it "reads doubled backslashes back" do
      expect(described_class.unescape(%(a \\\\ b))).to eq %(a \\ b)
    end

    it "inverts escape for text mixing quotes and backslashes" do
      [%(The "Great" \\ Escape), %(A. "Slash" Author), %(\\"), %(\\\\"), "Dvořák"].each do |text|
        expect(described_class.unescape(described_class.escape(text))).to eq text
      end
    end

    it "coerces non-strings" do
      expect(described_class.unescape(nil)).to eq ""
    end
  end
end
