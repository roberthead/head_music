# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::MusicalSymbol do
  context "given a generic named class" do
    describe "#construction" do
      subject(:symbol) do
        described_class.new(
          ascii: "#",
          unicode: "♯",
          html_entity: "&#9839;"
        )
      end

      its(:ascii) { is_expected.to eq "#" }
      its(:unicode) { is_expected.to eq "♯" }
      its(:html_entity) { is_expected.to eq "&#9839;" }
    end
  end
end
