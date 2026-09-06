require "spec_helper"

describe HeadMusic::Content::Voice do
  subject(:voice) { described_class.new(flow: flow) }

  let(:flow) { HeadMusic::Content::Flow.new }

  its(:flow) { is_expected.to eq flow }

  describe "#place" do
    let(:position) do
      HeadMusic::Content::Position.new(flow, "5:1:0")
    end

    it "adds a placement" do
      expect do
        voice.place(position, :quarter)
      end.to change {
        voice.placements.length
      }.by 1
    end

    describe "sorting" do
      let!(:fifth_method_position) { voice.place(HeadMusic::Content::Position.new(flow, "5:1:0"), :quarter) }
      let!(:fourth_method_position) { voice.place(HeadMusic::Content::Position.new(flow, "4:3:0"), :quarter) }

      it "sorts by position" do
        expect(voice.placements).to eq [fourth_method_position, fifth_method_position]
      end
    end

    context "when multiple notes are placed at the same position" do
      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("1:1", :quarter, "E4")
        voice.place("1:1", :quarter, "G4")
      end

      it "merges them into one chord placement, preserving placement order" do
        expect(voice.placements.length).to eq 1
        expect(voice.placements.first.pitches.map(&:to_s)).to eq %w[C4 E4 G4]
      end
    end

    context "when a pitch is placed again at the same position" do
      before do
        voice.place("1:1", :quarter, %w[C4 E4])
        voice.place("1:1", :quarter, "C4")
      end

      it "is idempotent" do
        expect(voice.placements.first.pitches.map(&:to_s)).to eq %w[C4 E4]
      end
    end

    context "when a note is placed on a same-duration rest" do
      before do
        voice.place("1:1", :quarter)
        voice.place("1:1", :quarter, "C4")
      end

      it "turns the rest into a note" do
        expect(voice.placements.length).to eq 1
        expect(voice.placements.first).to be_note
      end
    end

    context "when a rest is placed on a same-duration note" do
      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("1:1", :quarter)
      end

      it "leaves the note unchanged" do
        expect(voice.placements.length).to eq 1
        expect(voice.placements.first.pitches.map(&:to_s)).to eq %w[C4]
      end
    end

    context "when the durations differ at one position" do
      before { voice.place("1:1", :half, "C4") }

      it "raises ArgumentError naming both durations and the position" do
        expect { voice.place("1:1", :quarter, "E4") }
          .to raise_error(ArgumentError, "cannot place a quarter at 1:1:000: position occupied by a half")
      end
    end

    context "when merging into an existing placement" do
      it "returns the existing placement" do
        first = voice.place("1:1", :quarter, "C4")
        second = voice.place("1:1", :quarter, "E4")
        expect(second).to be first
      end
    end

    context "when given an array of pitches" do
      it "creates exactly one placement" do
        expect do
          voice.place("2:1", :half, %w[C4 E4 G4])
        end.to change { voice.placements.length }.by 1
      end
    end

    context "when notes are placed out of positional order around a chord" do
      before do
        voice.place("2:1", :quarter, "C4")
        voice.place("2:1", :quarter, "E4")
        voice.place("2:1", :quarter, "G4")
        voice.place("1:1", :quarter, "B3")
      end

      it "sorts by position and merges the co-positioned pitches" do
        expect(voice.placements.map { |placement| placement.pitches.map(&:to_s) }).to eq [["B3"], %w[C4 E4 G4]]
      end
    end

    context "when many notes arrive in shuffled order" do
      let(:positions) { (1..40).map { |bar| "#{bar}:1:000" } }

      before do
        positions.shuffle(random: Random.new(1)).each { |position| voice.place(position, :whole, "C4") }
      end

      it "keeps them in position order" do
        expect(voice.placements.map { |placement| placement.position.to_s }).to eq positions
      end

      it "merges a repeat of each position rather than adding one" do
        expect { positions.each { |position| voice.place(position, :whole, "E4") } }
          .not_to change(voice.placements, :length)
      end
    end
  end

  describe "#next_position" do
    context "when there are notes" do
      before do
        voice.place(HeadMusic::Content::Position.new(flow, "1:1:0"), :quarter, "C")
        voice.place(HeadMusic::Content::Position.new(flow, "1:2:0"), :quarter, "D")
        voice.place(HeadMusic::Content::Position.new(flow, "1:3:0"), :quarter, "E")
      end

      it "returns the position after the last note" do
        expect(voice.next_position).to eq HeadMusic::Content::Position.new(flow, "1:4:0")
      end
    end

    context "when there are no notes" do
      it "returns the first position" do
        expect(voice.next_position).to eq HeadMusic::Content::Position.new(flow, "1:1:0")
      end
    end
  end

  describe "#notes and #rests" do
    let!(:first_beat_d) { voice.place(HeadMusic::Content::Position.new(flow, "1:1:0"), :quarter, "D") }
    let!(:second_beat_rest) { voice.place(HeadMusic::Content::Position.new(flow, "1:2:0"), :quarter) }
    let!(:third_beat_g) { voice.place(HeadMusic::Content::Position.new(flow, "1:3:0"), :quarter, "G") }
    let!(:fourth_beat_rest) { voice.place(HeadMusic::Content::Position.new(flow, "1:4:0"), :quarter) }

    its(:notes) { are_expected.to eq [first_beat_d, third_beat_g] }
    its(:rests) { are_expected.to eq [second_beat_rest, fourth_beat_rest] }
  end

  describe "#notes with unpitched sounds" do
    let!(:pitched_note) { voice.place("1:1", :quarter, "C4") }
    let!(:mixed_placement) { voice.place("1:4", :quarter, ["E4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")]) }

    before do
      voice.place("1:2", :quarter, HeadMusic::Rudiment::UnpitchedSound.get)
      voice.place("1:3", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
    end

    it "excludes unpitched-only placements but includes mixed placements" do
      expect(voice.notes).to eq [pitched_note, mixed_placement]
    end
  end

  describe "#place with sounds" do
    it "accepts a bare unpitched instrument name" do
      placement = voice.place("1:1", :quarter, "snare drum")
      expect(placement.sounds.map(&:name_key)).to eq [:snare_drum]
    end

    it "accepts the generic unpitched sound" do
      placement = voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get)
      expect(placement).to be_unpitched_note
    end

    it "accepts an instrument-backed unpitched sound" do
      placement = voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("bass drum"))
      expect(placement.sounds.map(&:name_key)).to eq [:bass_drum]
    end

    it "accepts an unpitched instrument instance" do
      placement = voice.place("1:1", :quarter, HeadMusic::Instruments::Instrument.get("snare drum"))
      expect(placement).to be_unpitched_note
    end

    it "accepts a pitched instrument instance as an unpitched hit" do
      placement = voice.place("1:1", :quarter, HeadMusic::Instruments::Instrument.get("violin"))
      expect(placement.sounds.map(&:name_key)).to eq [:violin]
      expect(placement).not_to be_pitched
    end

    it "accepts a mixed array of pitches and unpitched sounds" do
      placement = voice.place("1:1", :quarter, ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")])
      expect(placement.pitches.map(&:to_s)).to eq ["C4"]
      expect(placement.sounds.length).to eq 2
    end

    it "raises for a bare pitched instrument name" do
      expect { voice.place("1:1", :quarter, "violin") }.to raise_error(ArgumentError, /pitched instrument/)
    end

    it "merges a pitched placement into an unpitched one at the same position" do
      voice.place("1:1", :quarter, "snare drum")
      placement = voice.place("1:1", :quarter, "C4")
      expect(voice.placements.length).to eq 1
      expect(placement).to be_pitched
      expect(placement.sounds.length).to eq 2
    end
  end

  describe "#notes_not_in_key" do
    context "with some accidentals" do
      before do
        %w[C D E F# G E C Bb3 C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it "returns the notes not in the key" do
        expect(voice.notes_not_in_key.map(&:pitch)).to eq %w[F#4 Bb3]
      end
    end
  end

  describe "melody" do
    before do
      %w[G3 C4 D4 Eb4 F4 Eb G3].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it "determines the intervals" do
      expect(voice.melodic_intervals.map(&:shorthand)).to eq %w[P4 M2 m2 M2 M2 m6]
    end

    its(:range) { is_expected.to eq "minor seventh" }
    its(:highest_pitch) { is_expected.to eq "F4" }
    its(:lowest_pitch) { is_expected.to eq "G3" }
    its(:highest_notes) { are_expected.to eq [voice.notes[4]] }
    its(:lowest_notes) { is_expected.to eq [voice.notes.first, voice.notes.last] }
    its(:leaps) { are_expected.to eq [voice.melodic_note_pairs[0], voice.melodic_note_pairs[5]] }
    its(:large_leaps) { are_expected.to eq [voice.melodic_note_pairs[0], voice.melodic_note_pairs[5]] }
    its(:to_s) { is_expected.to eq "G3 C4 D4 E♭4 F4 E♭4 G3" }
  end

  describe "#melodic_line" do
    before do
      voice.place("1:1", :whole, "C4")
      voice.place("2:1", :whole, "E4")
    end

    it "reads the melody as it stands when first asked" do
      expect(voice.melodic_note_pairs.length).to eq 1
    end

    it "rereads the melody after a later placement" do
      voice.melodic_note_pairs
      voice.place("3:1", :whole, "G4")
      expect(voice.melodic_note_pairs.length).to eq 2
    end

    it "rereads the intervals after a later placement" do
      voice.melodic_intervals
      voice.place("3:1", :whole, "G4")
      expect(voice.melodic_intervals.map(&:shorthand)).to eq %w[M3 m3]
    end
  end

  describe "#melodic_note_pairs" do
    context "when a note precedes a chord" do
      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter, %w[F3 A3 C4 F4])
      end

      it "uses the chord's top pitch" do
        expect(voice.melodic_note_pairs.first.pitches.map(&:to_s)).to eq %w[C4 F4]
      end
    end
  end

  context "when a role is provided" do
    subject(:voice) { described_class.new(flow: flow, role: "Cantus Firmus") }

    before do
      %w[G3 C4 D4 Eb4 F4 Eb G3].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_cantus_firmus }

    its(:role) { is_expected.to eq "Cantus Firmus" }
    its(:to_s) { is_expected.to eq "Cantus Firmus: G3 C4 D4 E♭4 F4 E♭4 G3" }
  end

  describe "note_at" do
    subject { voice.note_at(position) }

    let(:pitches) { %w[C E G F A G E D C] }

    before do
      pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    context "for a downbeat with a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:000") }

      its(:pitch) { is_expected.to eq "A4" }
    end

    context "for an offbeat in the middle of the duration of a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:2:000") }

      its(:pitch) { is_expected.to eq "A4" }
    end

    context "for a tick in the middle of the duration of a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:001") }

      its(:pitch) { is_expected.to eq "A4" }
    end

    context "for a downbeat where there is no note" do
      let(:pitches) { ["C", "E", "G", "F", nil, "G", "E", "D", "C"] }
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:000") }

      it { is_expected.to be_nil }
    end
  end

  describe "notes_during" do
    subject(:notes_during) { voice.notes_during(placement) }

    let(:pitches) { %w[C E G F A G E D C] }
    let(:placement) { HeadMusic::Content::Placement.new(flow, position, rhythmic_value) }

    before do
      pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    context "for a downbeat with a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:000") }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(notes_during.map(&:to_s)).to match ["whole A4 at 5:1:000"]
      end
    end

    context "for an offbeat in the middle of the duration of a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:2:000") }
      let(:rhythmic_value) { :quarter }

      specify do
        expect(notes_during.map(&:to_s)).to match ["whole A4 at 5:1:000"]
      end
    end

    context "for a tick in the middle of the duration of a note" do
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:001") }
      let(:rhythmic_value) { :"thirty-second" }

      specify do
        expect(voice.notes_during(placement).map(&:to_s)).to match ["whole A4 at 5:1:000"]
      end
    end

    context "for a downbeat where there is no note" do
      let(:pitches) { ["C", "E", "G", "F", nil, "G", "E", "D", "C"] }
      let(:position) { HeadMusic::Content::Position.new(flow, "5:1:000") }
      let(:rhythmic_value) { :"thirty-second" }

      it { is_expected.to eq [] }
    end

    context "for a duration where there are multiple notes during the placement" do
      let(:position) { HeadMusic::Content::Position.new(flow, "4:3:000") }
      let(:rhythmic_value) { :breve }

      specify do
        expect(notes_during.map(&:to_s)).to eq ["whole F4 at 4:1:000", "whole A4 at 5:1:000", "whole G4 at 6:1:000"]
      end
    end
  end

  describe "bar numbers" do
    context "when the voice is empty" do
      its(:earliest_bar_number) { is_expected.to eq 1 }
      its(:latest_bar_number) { is_expected.to eq 1 }
    end

    context "when the voice holds only rests" do
      before do
        voice.place("3:1", :whole)
        voice.place("4:1", :whole)
      end

      it "reports the bar of the first rest" do
        expect(voice.earliest_bar_number).to eq 3
      end

      it "reports the bar of the last rest" do
        expect(voice.latest_bar_number).to eq 4
      end
    end
  end

  describe "#first_gap" do
    subject(:first_gap) { voice.first_gap }

    context "when the voice has no placements" do
      it { is_expected.to be_nil }
    end

    context "when the placements are contiguous" do
      subject(:first_gap) { parsed_voice.first_gap }

      let(:parsed_flow) do
        HeadMusic::Notation::ABC.parse(<<~ABC)
          X:1
          T:Contiguous
          M:4/4
          L:1/4
          K:C
          C D E F | G A B c |
        ABC
      end
      let(:parsed_voice) { parsed_flow.voices.first }

      it { is_expected.to be_nil }
    end

    context "when a chord fills its beat in an otherwise contiguous voice" do
      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter, %w[E4 G4 C5])
        voice.place("1:3", :half, "C5")
      end

      it { is_expected.to be_nil }
    end

    context "when there is a gap between two placements" do
      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("2:1", :quarter, "D4")
      end

      it "returns the expected position and the placement found after the gap" do
        expected_position = HeadMusic::Content::Position.new(flow, "1:2:0")
        found_placement = voice.placements.last
        expect(first_gap).to eq [expected_position, found_placement]
      end
    end

    context "when the first placement does not start its bar" do
      before do
        voice.place("2:2:480", :quarter, "D4")
      end

      it "returns the start of the bar and the first placement" do
        expected_position = HeadMusic::Content::Position.new(flow, "2:1:0")
        expect(first_gap).to eq [expected_position, voice.placements.first]
      end
    end
  end

  describe "#to_h" do
    context "with placements" do
      let(:expected_hash) do
        {
          "role" => nil,
          "placements" => [
            {"position" => "1:1:000", "rhythmic_value" => "quarter", "sounds" => ["C4"]},
            {"position" => "1:2:000", "rhythmic_value" => "quarter", "sounds" => []}
          ]
        }
      end

      before do
        voice.place("1:1", :quarter, "C4")
        voice.place("1:2", :quarter)
      end

      it "serializes the placements in order" do
        expect(voice.to_h).to eq expected_hash
      end
    end

    context "when the role is a string" do
      subject(:voice) { described_class.new(flow: flow, role: "melody") }

      it "serializes the role" do
        expect(voice.to_h["role"]).to eq "melody"
      end
    end

    context "when the role is a symbol" do
      subject(:voice) { described_class.new(flow: flow, role: :melody) }

      it "serializes the role as a string" do
        expect(voice.to_h["role"]).to eq "melody"
      end
    end

    context "when the role is nil" do
      it "serializes the role as nil" do
        expect(voice.to_h["role"]).to be_nil
      end
    end
  end

  # Voice#place binary-searches over Position#<=>, so a comparator that is not
  # a total order does not raise -- it returns the wrong placement, and the
  # music is quietly wrong. A meter change is where a comparator that reasons
  # about elapsed time rather than coordinates comes apart, so notes are placed
  # across one here and both the ordering and the lookup are asserted.
  describe "placing notes across a meter change" do
    subject(:voice) { flow.add_voice }

    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap { |flow| flow.change_meter(3, "3/4") }
    end

    let(:codes) { ["1:1", "1:3", "2:1", "2:3", "3:1", "3:2", "3:3", "4:1", "4:2"] }

    before { codes.each { |code| voice.place(code, :quarter, "C4") } }

    it "keeps the placements in ascending position order" do
      positions = voice.placements.map(&:position)
      expect(positions).to eq positions.sort
    end

    it "places every note rather than merging any of them" do
      expect(voice.placements.map { |placement| placement.position.code })
        .to eq codes.map { |code| flow.position(code).code }
    end

    # place looks for an existing placement with a binary search before it
    # inserts, so replacing every note is the lookup exercised at every
    # position on both sides of the change.
    it "finds each existing placement again rather than duplicating it" do
      codes.each { |code| voice.place(code, :quarter, "D4") }
      expect(voice.placements.length).to eq codes.length
    end

    it "merges into the placement it found" do
      voice.place("3:2", :quarter, "D4")
      expect(voice.note_at(flow.position("3:2")).pitch.to_s).to eq "D4"
    end

    it "reports the meter change to the positions after it" do
      expect(flow.position("3:1").meter.to_s).to eq "3/4"
    end
  end

  # The epic's central requirement: a voice belongs to a part and *has* a staff
  # at any given moment, so a piano voice can start in the bass staff and cross
  # into the treble without leaving its part.
  describe "crossing between staves" do
    subject(:left_hand) { piano.add_voice(role: "left hand") }

    let(:flow) { HeadMusic::Content::Flow.new }
    let(:staff_system) { HeadMusic::Content::StaffSystem.grand_staff }
    let(:treble) { staff_system.staves.first }
    let(:bass) { staff_system.staves.last }
    let(:piano) { flow.add_part(instrument: "piano", staff_system: staff_system) }

    def clefs_through(bar_range)
      bar_range.map { |bar| left_hand.staff_at(bar).clef.to_s.split.first }
    end

    it "sits on the part's first staff until it says otherwise" do
      expect(left_hand.staff).to be treble
    end

    it "needs no assignments at all on a single-staff part" do
      expect(flow.add_part.add_voice.staff_assignments).to be_empty
    end

    context "with a span in the other staff" do
      before do
        left_hand.cross_to(bass, from: 1)
        left_hand.cross_to(treble, from: 5, through: 8)
      end

      it "reports a different staff on either side of the crossing" do
        expect(clefs_through(1..10))
          .to eq %w[bass bass bass bass treble treble treble treble bass bass]
      end

      # Not "the part's first staff": a left hand that rises for four bars
      # comes back down to the staff it was on, which is what it was written
      # on before the span.
      it "returns to the staff it was on before the span" do
        expect(left_hand.staff_at(9)).to be bass
      end

      it "records an event at each boundary" do
        expect(left_hand.staff_assignments.keys).to eq [1, 5, 9]
      end
    end

    # A single cross-staff note is a span of one bar. No note-level case.
    it "crosses for a single bar" do
      left_hand.cross_to(bass, from: 3, through: 3)
      expect(clefs_through(2..4)).to eq %w[treble bass treble]
    end

    it "crosses for the rest of the flow when given no end" do
      left_hand.cross_to(bass, from: 3)
      expect(clefs_through(2..99).uniq).to eq %w[treble bass]
    end

    it "refuses a staff the part does not have" do
      expect { left_hand.cross_to(HeadMusic::Content::Staff.new(clef: :alto_clef), from: 3) }
        .to raise_error ArgumentError, /not in the part's staff system/
    end
  end
end
