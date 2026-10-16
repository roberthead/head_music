require "spec_helper"

describe HeadMusic::Notation::MEI do
  def parse(*items, **options)
    described_class.parse(mei_document(*items, **options))
  end

  def eighths(*pitches, **attributes)
    pitches.each_with_index.map do |pitch, index|
      mei_note(pitch, "8", "xml:id": "n#{index + 1}", **attributes.transform_values { |values| values[index] }.compact)
    end.join
  end

  # One group of triplet eighths from the start of the bar, then a half.
  let(:triplet_bar) { [[["1+0", "1+1/4", "triplet", "eighth"]]] }
  let(:triplet_events) { ["triplet eighth C4 at 1:1:000", "triplet eighth D4 at 1:1:320", "triplet eighth E4 at 1:1:640", "dotted half F4 at 1:2:000"] }

  def triplet_flow(layer, controls = "")
    parse(mei_staff(1, layer + mei_note("F4", "2", dots: "1")) + controls)
  end

  describe "the triplets golden" do
    let(:source) { MEIFixtures.source("triplets") }
    let(:flow) { described_class.parse(File.read(MEIFixtures.path("triplets"))) }

    it "reads back its source's groups" do
      expect(tuplet_summary(flow)).to eq tuplet_summary(source)
    end

    it "reads back its source's events" do
      expect(flow.voices.first.voice_events.map(&:to_s)).to eq source.voices.first.voice_events.map(&:to_s)
    end
  end

  describe "<tuplet>" do
    it "scales its members and groups them" do
      flow = triplet_flow(%(<tuplet num="3" numbase="2">#{eighths("C4", "D4", "E4")}</tuplet>))
      expect([flow.voices.first.voice_events.map(&:to_s), bracket_summary(flow)]).to eq [triplet_events, triplet_bar]
    end

    it "scales a rest among its members" do
      flow = triplet_flow(%(<tuplet num="3" numbase="2">#{mei_note("C4", "8") + mei_rest("8") + mei_note("E4", "8")}</tuplet>))
      expect(flow.voices.first.voice_events[1].to_s).to eq "triplet eighth rest at 1:1:320"
    end

    it "takes an odd @num alone in the time of the power of two below it" do
      flow = triplet_flow(%(<tuplet num="3">#{eighths("C4", "D4", "E4")}</tuplet>))
      expect(bracket_summary(flow)).to eq triplet_bar
    end

    it "refuses one inside another" do
      inner = %(<tuplet num="3" numbase="2">#{eighths("C4", "D4", "E4")}</tuplet>)
      expect { triplet_flow(%(<tuplet num="5" numbase="4">#{inner}</tuplet>)) }
        .to raise_error(described_class::UnsupportedFeatureError, /Nested tuplets are not supported \(measure 1, staff 1, <tuplet>\)/)
    end
  end

  describe "<tupletSpan>" do
    it "scales and groups the members its @plist names" do
      flow = triplet_flow(eighths("C4", "D4", "E4"), %(<tupletSpan num="3" numbase="2" staff="1" plist="#n1 #n2 #n3"/>))
      expect([flow.voices.first.voice_events.map(&:to_s), bracket_summary(flow)]).to eq [triplet_events, triplet_bar]
    end

    it "scales and groups what it spans from @startid to @endid" do
      flow = triplet_flow(eighths("C4", "D4", "E4"), %(<tupletSpan num="3" numbase="2" staff="1" startid="#n1" endid="#n3"/>))
      expect([flow.voices.first.voice_events.map(&:to_s), bracket_summary(flow)]).to eq [triplet_events, triplet_bar]
    end

    it "scales nothing when placed only by beats" do
      span = ->(ids) { %(<tupletSpan num="3" numbase="2" staff="1" tstamp="1" tstamp2="0m+2"#{ids}/>) }
      expect(triplet_flow(eighths("C4", "D4", "E4"), span.call(%( startid="#n1" endid="#n3")))).to be_a HeadMusic::Content::Flow
      expect { triplet_flow(eighths("C4", "D4", "E4"), span.call("")) }.to raise_error(described_class::UnsupportedFeatureError, /longer than its 4\/4 bar/)
    end

    describe "whose @endid is not later in the layer it starts in" do
      def quarters(staff, bar)
        %w[C4 D4 E4 F4].each_with_index.map { |pitch, index| mei_note(pitch, "4", "xml:id": "s#{staff}b#{bar}n#{index + 1}") }.join
      end

      def values(flow)
        flow.voices.flat_map(&:voice_events).map { |event| event.rhythmic_value.to_s }.uniq
      end

      it "scales nothing when the end comes before the start" do
        span = %(<tupletSpan num="3" numbase="2" staff="1" startid="#s1b1n4" endid="#s1b1n1"/>)
        expect(values(parse(mei_staff(1, quarters(1, 1)) + span, mei_staff(1, quarters(1, 2))))).to eq ["quarter"]
      end

      it "scales nothing when the end is on another staff" do
        span = %(<tupletSpan num="3" numbase="2" staff="1" startid="#s1b1n2" endid="#s2b1n4"/>)
        bars = [1, 2].map { |bar| mei_staff(1, quarters(1, bar)) + mei_staff(2, quarters(2, bar)) + ((bar == 1) ? span : "") }
        expect(values(parse(*bars, score_def: mei_score_def(clefs: [%w[G 2], %w[G 2]])))).to eq ["quarter"]
      end
    end

    it "absorbs MEI Export's hidden tuplet in each bar into one group across the barline" do
      source = TupletFixtures.tuplet_crossing_barline
      expect(tuplet_summary(described_class.parse(source.to_mei))).to eq [[["1:4:000", "2:2:000", "triplet", "quarter"]]]
    end

    it "refuses a span over a <tuplet> of another ratio" do
      layer = %(<tuplet num="5" numbase="4">#{eighths("C4", "D4", "E4")}</tuplet>)
      expect { triplet_flow(layer, %(<tupletSpan num="3" numbase="2" staff="1" startid="#n1" endid="#n3"/>)) }
        .to raise_error(described_class::UnsupportedFeatureError, /Nested tuplets/)
    end
  end

  describe "@tuplet" do
    def tuplet(notes)
      %(<tuplet num="3" numbase="2">#{notes}</tuplet>)
    end

    it "groups a run that two bars' tuplets scale alike as one bracket across the barline" do
      bars = [
        mei_staff(1, mei_note("C4", "2", dots: "1") + tuplet(mei_note("D4", "4", tuplet: "i1") + mei_note("E4", "8", tie: "i"))),
        mei_staff(1, tuplet(mei_note("E4", "8", tie: "t") + mei_note("F4", "4", tuplet: "t1")) + mei_note("G4", "2", dots: "1"))
      ]
      expect(tuplet_summary(parse(*bars))).to eq [[["1:4:000", "2:2:000", "triplet", "quarter"]]]
    end

    it "refuses a level past the first, a nested tuplet" do
      layer = %(<tuplet num="3" numbase="2">#{eighths("C4", "D4", "E4", tuplet: ["i2", nil, "t2"])}</tuplet>)
      expect { triplet_flow(layer) }.to raise_error(described_class::UnsupportedFeatureError, /Nested tuplets/)
    end
  end
end
