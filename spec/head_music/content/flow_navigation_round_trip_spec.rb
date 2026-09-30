require "spec_helper"

describe HeadMusic::Content::Flow do
  def markings(flow)
    flow.bars.map(&:to_h)
  end

  def played(flow)
    flow.performance_order.map { |played_bar| [played_bar.number, played_bar.pass] }
  end

  shared_examples "a round trip that keeps the navigation" do
    it "keeps each bar's markings" do
      expect(markings(restored)).to eq markings(flow)
    end

    it "keeps the performance order" do
      expect(played(restored)).to eq played(flow)
    end
  end

  context "with a D.S. al Coda" do
    let(:flow) { NavigationFixtures.dal_segno_al_coda }

    it "plays through, back to the segno, and on to the coda" do
      expect(flow.performance_order.map(&:number)).to eq [1, 2, 3, 4, 2, 3, 5]
    end

    context "when round-tripped through Flow JSON" do
      let(:restored) { described_class.from_json(flow.to_json) }

      it_behaves_like "a round trip that keeps the navigation"
    end

    context "when round-tripped through ABC" do
      let(:restored) { HeadMusic::Notation::ABC.parse(flow.to_abc) }

      it_behaves_like "a round trip that keeps the navigation"
    end

    context "when round-tripped through LilyPond" do
      let(:restored) { HeadMusic::Notation::LilyPond.parse(flow.to_lilypond) }

      it_behaves_like "a round trip that keeps the navigation"
    end
  end

  context "with repeats, endings, and a D.C. al Fine" do
    let(:flow) { NavigationFixtures.da_capo_al_fine }

    context "when round-tripped through Flow JSON" do
      let(:restored) { described_class.from_json(flow.to_json) }

      it_behaves_like "a round trip that keeps the navigation"
    end

    context "when round-tripped through ABC" do
      let(:restored) { HeadMusic::Notation::ABC.parse(flow.to_abc) }

      it_behaves_like "a round trip that keeps the navigation"
    end
  end

  context "with two coda signs and no jump" do
    let(:flow) do
      described_class.new.tap do |two_codas|
        voice = two_codas.add_voice
        1.upto(4) { |bar| voice.place("#{bar}:1:000", :whole, "C4") }
        two_codas.bar(2).coda = true
        two_codas.bar(4).coda = true
      end
    end

    context "when round-tripped through ABC" do
      let(:restored) { HeadMusic::Notation::ABC.parse(flow.to_abc) }

      it_behaves_like "a round trip that keeps the navigation"
    end

    context "when round-tripped through LilyPond" do
      let(:restored) { HeadMusic::Notation::LilyPond.parse(flow.to_lilypond) }

      it_behaves_like "a round trip that keeps the navigation"
    end
  end

  context "with a segno and a coda sign on one bar, in two voices" do
    let(:flow) do
      described_class.new.tap do |shared_bar|
        2.times do
          voice = shared_bar.add_voice
          1.upto(3) { |bar| voice.place("#{bar}:1:000", :whole, "C4") }
        end
        shared_bar.bar(2).segno = true
        shared_bar.bar(2).coda = true
      end
    end

    context "when round-tripped through LilyPond" do
      let(:restored) { HeadMusic::Notation::LilyPond.parse(flow.to_lilypond) }

      it_behaves_like "a round trip that keeps the navigation"
    end
  end
end
