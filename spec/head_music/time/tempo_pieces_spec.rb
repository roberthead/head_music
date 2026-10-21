require "spec_helper"

describe HeadMusic::Time::TempoPieces do
  subject(:tempo_pieces) do
    described_class.new(
      tempo_map: tempo_map, meter_scale: meter_scale, start: subticks(starting_position),
      tempo_ramps: tempo_ramps, fermatas: fermatas
    )
  end

  let(:tempo_map) { HeadMusic::Time::TempoMap.new(starting_tempo: tempo(120)) }
  let(:meter_scale) { HeadMusic::Time::MeterScale.new(HeadMusic::Time::MeterMap.new(starting_meter: "4/4")) }
  let(:starting_position) { position(1) }
  let(:tempo_ramps) { [] }
  let(:fermatas) { [] }
  let(:pieces) { tempo_pieces.pieces }

  def position(bar, count = 1)
    HeadMusic::Time::MusicalPosition.new(bar, count, 0, 0)
  end

  def subticks(position)
    meter_scale.subticks_at(position)
  end

  def tempo(beats_per_minute)
    HeadMusic::Rudiment::Tempo.new("quarter", beats_per_minute)
  end

  def bounds
    pieces.map { |piece| [piece.start, piece.finish] }
  end

  context "with one tempo" do
    it "is one open-ended piece from the start" do
      expect(bounds).to eq [[0, nil]]
    end

    it "holds the tempo at its speed without a fermata" do
      expect(pieces.first).to have_attributes(
        tempo: tempo_map.events.first.tempo, speed: HeadMusic::Time::TempoPiece.speed_of(tempo(120)), slope: 0, stretch: 1
      )
    end
  end

  context "with a tempo change at bar 3" do
    before { tempo_map.add_change(position(3), tempo(60)) }

    it "breaks at the change" do
      expect(bounds).to eq [[0, subticks(position(3))], [subticks(position(3)), nil]]
    end

    it "takes the new tempo after the change" do
      expect(pieces.last.tempo.beats_per_minute).to eq 60
    end

    context "when starting after the change" do
      let(:starting_position) { position(4) }

      it "begins at the start in the tempo in force there" do
        expect([bounds, pieces.first.tempo.beats_per_minute]).to eq [[[subticks(position(4)), nil]], 60]
      end
    end
  end

  context "with a ramp from bar 2 to bar 3" do
    let(:tempo_ramps) { [HeadMusic::Time::TempoRamp.new(from: position(2), to: position(3), to_tempo: tempo(60))] }

    it "breaks at both ends of the ramp" do
      expect(bounds.map(&:first)).to eq [0, subticks(position(2)), subticks(position(3))]
    end

    it "changes speed across the ramp and holds the target after it" do
      expect(pieces.map(&:ramp?)).to eq [false, true, false]
    end

    it "ends the ramp at its target" do
      expect(pieces.last.speed).to eq HeadMusic::Time::TempoPiece.speed_of(tempo(60))
    end

    it "ignores a tempo change inside the ramp" do
      tempo_map.add_change(position(2, 3), tempo(200))
      expect(bounds.size).to eq 3
    end
  end

  context "with a fermata inside a ramp" do
    let(:tempo_ramps) { [HeadMusic::Time::TempoRamp.new(from: position(1), to: position(3), to_tempo: tempo(60))] }
    let(:fermatas) { [HeadMusic::Time::Fermata.new(from: position(2), to: position(2, 2), stretch: 3)] }

    it "breaks the ramp at both ends of the fermata" do
      expect(bounds.map(&:first)).to eq [0, subticks(position(2)), subticks(position(2, 2)), subticks(position(3))]
    end

    it "stretches only the held piece" do
      expect(pieces.map(&:stretch)).to eq [1, 3, 1, 1]
    end

    it "continues the ramp's speed through the fermata" do
      held = pieces[1]
      expect(held.speed).to eq pieces.first.speed_at(held.start)
    end
  end

  context "with overlapping fermatas" do
    let(:fermatas) do
      [
        HeadMusic::Time::Fermata.new(from: position(2), to: position(3), stretch: 2),
        HeadMusic::Time::Fermata.new(from: position(1, 3), to: position(2, 3), stretch: 4)
      ]
    end

    it "holds with the fermata given first where they overlap" do
      expect(pieces.map(&:stretch)).to eq [1, 4, 2, 2, 1]
    end
  end

  describe "#piece_at" do
    before { tempo_map.add_change(position(3), tempo(60)) }

    it "finds the piece sounding at a point" do
      expect(tempo_pieces.piece_at(subticks(position(3, 2)))).to eq pieces.last
    end

    it "finds the piece starting exactly at a point" do
      expect(tempo_pieces.piece_at(subticks(position(3)))).to eq pieces.last
    end

    it "falls back to the first piece before the start" do
      expect(tempo_pieces.piece_at(-1)).to eq pieces.first
    end
  end
end
