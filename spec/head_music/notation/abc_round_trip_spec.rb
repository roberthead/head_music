require "spec_helper"

describe HeadMusic::Notation::ABC do
  describe "a round trip of articulations, ornaments, and dynamics" do
    let(:original) { MarkingFixtures.marked_melody }
    let(:round_tripped) { described_class.parse(described_class.render(original)) }

    it "keeps every marking and the dynamic in force at every note event" do
      expect_same_markings(original, round_tripped)
    end

    it "keeps the pitches and rhythm" do
      expect(round_tripped.voices.first.voice_events.map(&:to_s))
        .to eq original.voices.first.voice_events.map(&:to_s)
    end

    it "reads back what it wrote" do
      rendered = described_class.render(original)
      expect(described_class.render(described_class.parse(rendered))).to eq rendered
    end
  end

  describe "a round trip of dynamics where no note starts" do
    def tune(body)
      described_class.parse("X:1\nT:Placed Dynamics\nM:4/4\nL:1/4\nK:C\n#{body}\n")
    end

    {
      "a voice p under a dotted half" => ["c3 d|", [[:voice, "1:2", :p]]],
      "a part p under a dotted half" => ["c3 d|", [[:part, "1:2", :p]]],
      "a p and an f in one note" => ["C4|", [[:voice, "1:2", :p], [:part, "1:3:480", :f]]],
      "a p one sixteenth into a whole note" => ["C4|", [[:voice, "1:1:240", :p]]],
      "a p in the second bar of a tied note" => ["z2 C2-|C4|", [[:voice, "2:2", :p]]],
      "a p under a chord" => ["[CEG]4|", [[:voice, "1:3", :p]]],
      "a p under a rest" => ["C2 z2|", [[:voice, "1:4", :p]]],
      "an f after the last note" => ["C D E|", [[:voice, "1:4", :f]]]
    }.each do |description, (body, dynamics)|
      context "with #{description}" do
        let(:original) do
          tune(body).tap do |flow|
            voice = flow.voices.first
            dynamics.each { |owner, position, level| ((owner == :part) ? voice.part : voice).place_dynamic(position, level) }
          end
        end
        let(:rendered) { described_class.render(original) }
        let(:round_tripped) { described_class.parse(rendered) }

        it "keeps each dynamic at its position, on the voice" do
          expect_same_dynamic_positions(original, round_tripped, merged_into: "voice 0")
        end

        it "keeps every voice event whole" do
          expect_same_voice_events(original, round_tripped)
        end

        it "reads back what it wrote" do
          expect(described_class.render(round_tripped)).to eq rendered
        end
      end
    end
  end

  describe "a round trip of hairpins" do
    # The ABC reader reads no pickup, for notes either, so the pickup fixture
    # cannot come back where it was.
    single_voice_fixtures = (HairpinFixtures.all - [:hairpin_in_pickup])
      .select { |fixture| HairpinFixtures.public_send(fixture).voices.one? }

    single_voice_fixtures.each do |fixture|
      context "with the #{fixture} fixture" do
        let(:original) { HairpinFixtures.public_send(fixture) }
        let(:rendered) { described_class.render(original) }
        let(:round_tripped) { described_class.parse(rendered) }

        it "keeps where each hairpin starts and ends, on the voice" do
          expect_same_hairpins(original, round_tripped, merged_into: "voice 0")
        end

        it "keeps the hairpin in force wherever one starts or ends" do
          expect_same_hairpin_in_force(original, round_tripped)
        end

        # ABC cannot tie a rest, so a rest across a barline reads back in two.
        unless fixture == :hairpin_on_split_rest
          it "keeps every voice event whole" do
            expect_same_voice_events(original, round_tripped)
          end
        end

        it "reads back what it wrote" do
          expect(described_class.render(round_tripped)).to eq rendered
        end
      end
    end

    it "reads a rest split at a barline back as two rests, since ABC cannot tie a rest" do
      round_tripped = described_class.parse(described_class.render(HairpinFixtures.hairpin_on_split_rest))
      expect(voice_event_summary(round_tripped)).to eq [
        ["half C4 at 1:1:000", "half rest at 1:3:000", "half rest at 2:1:000", "half D4 at 2:3:000"]
      ]
    end

    describe "of generated flows" do
      def round_trip(seed)
        original = HairpinGenerator.flow(seed, voices: 1, one_line: true, pickup: false)
        rendered = described_class.render(original)
        [original, rendered, described_class.parse(rendered)]
      end

      def note_summary(flow)
        duration_writer = HeadMusic::Notation::ABC::DurationWriter.new(Rational(1, 8))
        flow.voices.first.note_events.map do |note_event|
          [note_event.position.to_s, note_event.pitches.map(&:to_s), duration_writer.multiplier_string(note_event.rhythmic_value)]
        end
      end

      # Notes are compared by length rather than by how their ties are
      # spelled, and rests not at all, since ABC cannot tie a rest across a
      # barline.
      HairpinGenerator::SEEDS.each do |seed|
        it "keeps the hairpins and notes of seed #{seed}, and reads back what it wrote" do
          original, rendered, round_tripped = round_trip(seed)
          expect_same_hairpins(original, round_tripped, merged_into: "voice 0")
          expect(note_summary(round_tripped)).to eq note_summary(original)
          expect(described_class.render(round_tripped)).to eq rendered
        end
      end
    end
  end

  describe "a round trip of slurs and phrases" do
    def round_trip(flow)
      described_class.parse(described_class.render(flow))
    end

    it "keeps the melody's music" do
      expect_abc_round_trip(MarkingFixtures.spanned_melody)
    end

    it "keeps where each slur starts and ends, and brings the phrase back as a slur drawn in to its notes" do
      expect(span_summary(round_trip(MarkingFixtures.spanned_melody))).to eq [[
        "slur from 1:1:000 to 1:3:000", "slur from 1:1:000 to 4:2:000", "slur from 2:1:000 to 2:4:000",
        "slur from 2:2:000 to 2:3:000", "slur from 3:4:000 to 4:2:000"
      ]]
    end

    it "brings back touching slurs with the second starting a note later" do
      expect(span_summary(round_trip(MarkingFixtures.touching_slurs)))
        .to eq [["slur from 1:1:000 to 1:3:000", "slur from 1:4:000 to 2:1:000"]]
    end

    it "reads back what it wrote" do
      rendered = described_class.render(MarkingFixtures.spanned_melody)
      expect(described_class.render(described_class.parse(rendered))).to eq rendered
    end
  end

  describe "a round trip of bar markings" do
    def played(flow)
      flow.performance_order.map { |played_bar| [played_bar.number, played_bar.pass] }
    end

    {
      "a D.S. al Coda" => [
        :dal_segno_al_coda,
        [[1, 1], [2, 1], [3, 1], [4, 1], [2, 1], [3, 1], [5, 1]]
      ],
      "a repeat with endings and a D.C. al Fine" => [
        :da_capo_al_fine,
        [[1, 1], [2, 1], [1, 2], [3, 2], [4, 1], [5, 1], [6, 1], [7, 1], [1, 2], [3, 2]]
      ]
    }.each do |description, (fixture, order)|
      context "with #{description}" do
        let(:original) { NavigationFixtures.public_send(fixture) }
        let(:rendered) { described_class.render(original) }
        let(:round_tripped) { described_class.parse(rendered) }

        it "is played in the order its markings spell" do
          expect(played(original)).to eq order
        end

        it "keeps every bar's markings" do
          expect(round_tripped.bars.map(&:to_h)).to eq original.bars.map(&:to_h)
        end

        it "keeps the order the bars are played in" do
          expect(played(round_tripped)).to eq played(original)
        end

        it "keeps the music" do
          expect_abc_round_trip(original)
        end

        it "reads back what it wrote" do
          expect(described_class.render(round_tripped)).to eq rendered
        end
      end
    end

    it "writes the D.S. al Coda's markings where the parser reads them" do
      expect(described_class.render(NavigationFixtures.dal_segno_al_coda).lines.drop(5).join).to eq <<~ABC
        [P:A]C2 D2 E2 F2!segno!|G2 A2 B2 c2|[P:B]d2 c2 B2 A2!dacoda!|G2 F2 E2 D2!D.S.alcoda!!coda!||
        C2 E2 G2 c2|]
      ABC
    end

    it "writes the repeat, its endings, and the D.C. al Fine" do
      expect(described_class.render(NavigationFixtures.da_capo_al_fine).lines.drop(5).join).to eq <<~ABC
        |:[P:A]G2 A2 B2|[1 c2 B2 A2:|[2 c4 d2!fine!||[P:B]e2 d2 c2|
        B2 A2 G2|A2 G2 F2|G6!D.C.alfine!|]
      ABC
    end
  end
end
