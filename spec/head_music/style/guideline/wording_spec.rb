require "spec_helper"

describe HeadMusic::Style::Guideline::Wording do
  describe "#count_values" do
    it "pairs a count with its number word" do
      expect(HeadMusic::Style::Guideline.count_values(8)).to eq(count: 8, number: "eight")
    end

    it "spells the number in the current locale" do
      I18n.with_locale(:de) do
        expect(HeadMusic::Style::Guideline.count_values(3)[:number]).to eq "drei"
      end
    end

    it "feeds the templates of the guidelines that count" do
      expect(HeadMusic::Style::Guidelines::MinimumNotes.template_values(minimum: 5))
        .to eq HeadMusic::Style::Guideline.count_values(5)
    end
  end
end
