require "spec_helper"

describe HeadMusic::Analysis::KeyFinder do
  describe "::KEYS" do
    subject(:keys) { described_class::KEYS }

    let(:major_tonics) { %w[C D♭ D E♭ E F G♭ G A♭ A B♭ B] }
    let(:minor_tonics) { %w[C C♯ D E♭ E F F♯ G G♯ A B♭ B] }

    it "lists the twelve major keys, then the twelve minor keys" do
      expect(keys.map(&:name)).to eq major_tonics.map { |tonic| "#{tonic} major" } + minor_tonics.map { |tonic| "#{tonic} minor" }
    end

    it "holds Keys" do
      expect(keys).to all(be_a(HeadMusic::Rudiment::Key))
    end

    it "covers every tonic pitch class in each quality" do
      keys.group_by(&:quality).each_value do |quality_keys|
        expect(quality_keys.map { |key| key.tonic_spelling.pitch_class.to_i }).to eq (0..11).to_a
      end
    end

    it "takes no signature past six accidentals" do
      expect(keys.map { |key| key.key_signature.num_alterations }.max).to eq 6
    end
  end

  describe "#key and #candidates" do
    let(:story_notes) { [[60, "1:1", :quarter], [62, "1:2", :quarter], [63, "1:3", :quarter], [65, "1:4", :quarter], [67, "2:1", :half]] }

    it "finds the story example in C minor" do
      expect(described_class.new(story_notes, meter: "4/4").key).to eq HeadMusic::Rudiment::Key.get("C minor")
    end

    it "uses Aarden-Essen by default" do
      expect(described_class.new(story_notes, meter: "4/4").profile.name).to eq :aarden_essen
    end

    it "takes another profile by name" do
      expect(described_class.new(story_notes, meter: "4/4", profile: :temperley).key.name).to eq "C minor"
    end

    context "when the profile ties two keys" do
      subject(:finder) { described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler) }

      it "ties G minor and C minor exactly" do
        expect(finder.candidates.first(2).map(&:correlation).uniq.length).to eq 1
      end

      it "prefers the key with fewer accidentals" do
        expect(finder.candidates.first(2).map { |candidate| candidate.key.name }).to eq ["G minor", "C minor"]
      end
    end

    it "breaks a tie by fewer accidentals, then major before minor, then the lower tonic" do
      finder = described_class.new([[60, 0, 1], [62, 0, 1], [64, 0, 1], [65, 0, 1], [67, 0, 1], [69, 0, 1], [71, 0, 1], [61, 0, 1], [63, 0, 1], [66, 0, 1], [68, 0, 1], [70, 0, 1]])
      expect(finder.candidates.first(3).map { |candidate| candidate.key.name }).to eq ["C major", "A minor", "F major"]
    end

    it "ranks all 24 keys with their correlations, best first" do
      candidates = described_class.new(story_notes, meter: "4/4").candidates
      expect(candidates.map(&:key)).to match_array described_class::KEYS
      expect(candidates.map(&:correlation)).to eq candidates.map(&:correlation).sort.reverse
    end

    it "weights each pitch class by how long it sounds" do
      long_g = [[60, 0, Rational(1, 4)], [64, Rational(1, 4), Rational(1, 4)], [67, Rational(1, 2), 2], [71, Rational(5, 2), Rational(1, 4)], [62, Rational(11, 4), Rational(1, 4)]]
      long_b = [[60, 0, Rational(1, 4)], [64, Rational(1, 4), Rational(1, 4)], [67, Rational(1, 2), Rational(1, 4)], [71, Rational(3, 4), 2], [62, Rational(11, 4), Rational(1, 4)]]
      expect([long_g, long_b].map { |notes| described_class.new(notes).key.name }).to eq ["C major", "G major"]
    end

    it "answers the same result for the same input" do
      first = described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler).candidates
      expect(described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler).candidates).to eq first
    end

    it "raises on an unknown profile" do
      expect { described_class.new(story_notes, meter: "4/4", profile: :nonesuch) }.to raise_error(ArgumentError, /unknown key profile/)
    end

    context "with no notes" do
      subject(:finder) { described_class.new([]) }

      it "answers no key and no candidates" do
        expect(finder.key).to be_nil
        expect(finder.candidates).to eq []
      end
    end

    context "with grace notes alone, which take no time" do
      subject(:finder) { described_class.new([[61, 0, 0], [62, 0, 0]]) }

      it "answers no key" do
        expect(finder.key).to be_nil
      end
    end

    context "with a flow of unpitched sounds" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :half, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
          voice.place("1:3", :half)
        end
      end

      it "answers no key and no candidates" do
        finder = described_class.new(flow)
        expect([finder.key, finder.candidates]).to eq [nil, []]
      end
    end
  end

  describe "#regions" do
    # Each bar sounds its key's tonic triad and leading tone, the tonic longest.
    def bar_in(tonic, bar_index)
      onset = Rational(bar_index)
      [[0, Rational(3, 8)], [4, Rational(1, 4)], [7, Rational(1, 4)], [-1, Rational(1, 8)]].map do |offset, duration|
        [tonic + offset, onset, duration].tap { onset += duration }
      end
    end

    def bars_in(*tonics)
      tonics.each_with_index.flat_map { |tonic, bar_index| tonic ? bar_in(tonic, bar_index) : [] }
    end

    def summary(finder)
      finder.regions.map { |region| [region.bar_number, region.onset, region.key.name] }
    end

    let(:c_g_c) { bars_in(*[60] * 4, *[67] * 4, *[60] * 4) }

    it "finds a modulation and the return, starting each region at a downbeat" do
      finder = described_class.new(c_g_c, meter: "4/4", change_penalty: 0.5)
      expect(summary(finder)).to eq [[1, 0, "C major"], [5, 4, "G major"], [9, 8, "C major"]]
    end

    it "holds the key through four bars of the dominant at the default penalty" do
      expect(summary(described_class.new(c_g_c, meter: "4/4"))).to eq [[1, 0, "C major"]]
    end

    it "uses a change penalty of 1.0 and scores each bar alone by default" do
      finder = described_class.new(c_g_c, meter: "4/4")
      expect([finder.change_penalty, finder.window]).to eq [1.0, 0]
    end

    it "does not switch key for one chromatic bar at the default penalty" do
      notes = bars_in(60, 60, 60, 62, 60, 60) + [[66, 3, Rational(1, 8)], [61, Rational(25, 8), Rational(1, 8)]]
      expect(summary(described_class.new(notes, meter: "4/4"))).to eq [[1, 0, "C major"]]
    end

    it "lets a wider window smooth a short excursion away" do
      notes = bars_in(60, 60, 67, 67, 60, 60)
      narrow = described_class.new(notes, meter: "4/4", change_penalty: 0.3)
      wide = described_class.new(notes, meter: "4/4", change_penalty: 0.3, window: 2)
      expect([summary(narrow).length, summary(wide).length]).to eq [3, 1]
    end

    it "carries the key through empty bars" do
      notes = bars_in(60, 60, nil, nil, 67, 67, 67, 67)
      finder = described_class.new(notes, meter: "4/4", change_penalty: 0.5)
      expect(summary(finder)).to eq [[1, 0, "C major"], [5, 4, "G major"]]
    end

    it "starts the first region at the first bar, even when it is silent" do
      notes = bars_in(nil, 67, 67)
      expect(summary(described_class.new(notes, meter: "4/4"))).to eq [[1, 0, "G major"]]
    end

    it "begins a pickup's region at bar 0" do
      notes = [[67, 0, Rational(1, 4)], *bars_in(60, 60).map { |number, onset, duration| [number, onset + Rational(1, 4), duration] }]
      finder = described_class.new(notes, bars: [0, Rational(1, 4), Rational(5, 4)], first_bar: 0)
      expect(summary(finder)).to eq [[0, 0, "C major"]]
    end

    it "credits a note held across a barline to each bar it sounds in" do
      first_bar = [[60, 0, Rational(1, 4)], [64, Rational(1, 4), Rational(1, 4)]]
      second_bar = [[62, 1, Rational(1, 8)], [66, Rational(9, 8), Rational(1, 8)], [69, Rational(5, 4), Rational(1, 8)], [62, Rational(11, 8), Rational(1, 8)]]
      short_g = described_class.new(first_bar + [[67, Rational(1, 2), Rational(1, 2)]] + second_bar, meter: "4/4", change_penalty: 0)
      held_g = described_class.new(first_bar + [[67, Rational(1, 2), Rational(3, 2)]] + second_bar, meter: "4/4", change_penalty: 0)
      expect([summary(short_g).last, summary(held_g).last]).to eq [[2, 1, "D major"], [1, 0, "C major"]]
    end

    it "keeps the key in force on a tie" do
      notes = bars_in(60) + [[60, 1, 1], [67, 1, 1]] + [[48, 2, 1], [55, 2, 1]]
      finder = described_class.new(notes, meter: "4/4", change_penalty: 0)
      expect(summary(finder)).to eq [[1, 0, "C major"]]
    end

    describe "the spelling of each region's tonic" do
      def tonics(*tonics)
        finder = described_class.new(bars_in(*tonics.flat_map { |tonic| [tonic] * 4 }), meter: "4/4", change_penalty: 0.5)
        finder.regions.map { |region| region.key.name }
      end

      it "spells a later region's tonic by the enharmonic nearer the previous region's" do
        expect([tonics(71, 66, 73), tonics(61, 66)]).to eq [["B major", "F♯ major", "C♯ major"], ["D♭ major", "G♭ major"]]
      end

      it "spells no key past seven accidentals" do
        expect(tonics(64, 71, 66, 73, 68).last(2)).to eq ["C♯ major", "A♭ major"]
      end
    end

    it "answers the same regions for the same input" do
      first = described_class.new(c_g_c, meter: "4/4", change_penalty: 0.5).regions
      expect(described_class.new(c_g_c, meter: "4/4", change_penalty: 0.5).regions).to eq first
    end

    it "answers no regions when nothing sounds" do
      expect(described_class.new([], meter: "4/4").regions).to eq []
    end

    it "raises on a negative change penalty" do
      expect { described_class.new(c_g_c, change_penalty: -0.1) }.to raise_error(ArgumentError, /change_penalty: must not be negative/)
    end

    it "raises on a window that is not a non-negative Integer" do
      expect { described_class.new(c_g_c, window: -1) }.to raise_error(ArgumentError, /window: must be a non-negative Integer/)
      expect { described_class.new(c_g_c, window: 1.5) }.to raise_error(ArgumentError, /window: must be a non-negative Integer/)
    end

    context "with Bach's Invention No. 1" do
      let(:flow) { HeadMusic::Notation::LilyPond.parse(File.read(File.expand_path("../../fixtures/notation/lily_pond/bach_invention_01.ly", __dir__))) }
      let(:input) { HeadMusic::Analysis::NoteInput.for(flow) }

      it "reads one C major region at the default penalty, as the signature is written" do
        expect(summary(described_class.new(input))).to eq [[1, 0, "C major"]]
      end

      it "follows the modulations at a lower penalty" do
        regions = described_class.new(input, change_penalty: 0.4).regions
        expect(regions.map { |region| [region.bar_number, region.key.name] }).to eq [
          [1, "C major"], [4, "G major"], [9, "D minor"], [12, "A minor"], [15, "C major"]
        ]
      end
    end
  end
end
