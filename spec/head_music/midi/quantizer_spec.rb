require "spec_helper"

describe HeadMusic::MIDI::Quantizer do
  let(:division) { 96 }

  def note(on, off, key: 60, channel: 0)
    [HeadMusic::MIDI::NoteOn.new(tick: on, channel: channel, key: key, velocity: 80), HeadMusic::MIDI::NoteOff.new(tick: off, channel: channel, key: key)]
  end

  def meter(tick, numerator, denominator)
    HeadMusic::MIDI::TimeSignature.new(tick, numerator, denominator, 24)
  end

  def quantizer(events, grid: :auto)
    sequence = HeadMusic::MIDI::Reader.new(HeadMusic::MIDI::SMF.file(division: division, tracks: [events])).read
    budget = HeadMusic::MIDI::Budget.new(sequence)
    layout = HeadMusic::MIDI::BarLayout.new(budget.time_signatures, division: division, end_tick: budget.end_tick)
    described_class.new(layout, sequence.notes, division: division, grid: grid)
  end

  def spans(quantizer)
    quantizer.notes.map { |note| [note.onset, note.release] }
  end

  describe "the automatic grid" do
    it "places an onset a tick late on the grid point it misses" do
      subject = quantizer([*note(0, 64), *note(64, 128), *note(129, 192)])
      expect([subject.grid, subject.notes.map(&:onset)]).to eq [1/24r, [0r, 1/6r, 1/3r]]
    end

    context "with triplet eighths at division 1024" do
      let(:division) { 1024 }
      let(:onsets) { Array.new(7) { |index| (index * 1024/3r).round } }

      it "chooses triplet sixteenths and snaps each onset exactly" do
        subject = quantizer(onsets.each_cons(2).flat_map { |on, off| note(on, off - 1) })
        expect([subject.grid, subject.notes.map(&:onset)]).to eq [1/24r, Array.new(6) { |index| Rational(index, 12) }]
      end
    end

    it "chooses from onsets alone, however far releases fall from the grid" do
      subject = quantizer([*note(0, 37), *note(64, 101)])
      expect(subject.grid).to eq 1/24r
    end

    it "falls back to the grid placing the most onsets within a tick" do
      expect(quantizer([*note(0, 1), *note(2, 3), *note(8, 9)]).grid).to eq 1/48r
    end

    it "breaks a tie in the fallback toward the coarser grid" do
      expect(quantizer([*note(0, 1), *note(2, 3), *note(16, 17), *note(32, 33)]).grid).to eq 1/24r
    end

    it "falls back to a coarser grid that places at least 99% as many onsets as the best" do
      onsets = Array.new(200) { |index| index * 8 } + [1604, 1610]
      expect(quantizer(onsets.flat_map { |on| note(on, on + 1) }).grid).to eq 1/48r
    end
  end

  describe "snapping" do
    let(:pickup) { [meter(0, 3, 4), meter(32, 3, 4)] }

    it "measures from each bar's downbeat, after a pickup off the grid" do
      subject = quantizer([*pickup, *note(0, 32), *note(32, 56), *note(56, 80), *note(80, 320)])
      expect([subject.grid, subject.notes.map(&:onset)]).to eq [1/16r, [0r, 1/12r, 1/12r + 1/16r, 1/12r + 1/8r]]
    end

    it "rounds a tick halfway between grid points up" do
      subject = quantizer([*pickup, *note(0, 32), *note(44, 320)], grid: 1/16r)
      expect(subject.notes.last.onset).to eq 1/12r + 1/16r
    end

    it "snaps a meta event's tick the same way" do
      expect(quantizer([*pickup, *note(0, 320)], grid: 1/16r).snap(44)).to eq 1/12r + 1/16r
    end
  end

  describe "releases" do
    context "with division 480" do
      let(:division) { 480 }

      it "reach the next onset from a tick early" do
        subject = quantizer([0, 160, 320, 480].each_cons(2).flat_map { |on, off| note(on, off - 1) })
        expect(spans(subject)).to eq [[0r, 1/12r], [1/12r, 1/6r], [1/6r, 1/4r]]
      end

      it "reach the next onset from 97 ticks early, as MuseScore ends a whole note" do
        subject = quantizer([*note(0, 1823), *note(1920, 3840)])
        expect(spans(subject)).to eq [[0r, 1r], [1r, 2r]]
      end

      it "reach past onsets the note sounds through, to the next after it ends" do
        inner = [0, 480, 960, 1440].flat_map { |on| note(on, on + 400, key: 72) }
        subject = quantizer([*note(0, 1823), *inner, *note(1920, 3840)])
        expect(spans(subject)).to eq [[0r, 1r], [0r, 1/4r], [1/4r, 1/2r], [1/2r, 3/4r], [3/4r, 1r], [1r, 2r]]
      end
    end

    context "with K525's gate times at division 256" do
      let(:division) { 256 }

      it "reach the next onset when the gap is under a step, and snap otherwise" do
        gated = [[0, 83], [128, 179], [192, 243], [256, 333], [384, 486], [512, 614], [768, 870]]
        subject = quantizer(gated.flat_map { |on, off| note(on, off) })
        expect(spans(subject)).to eq [
          [0r, 1/8r], [1/8r, 3/16r], [3/16r, 1/4r], [1/4r, 3/8r], [3/8r, 1/2r], [1/2r, 5/8r], [3/4r, 7/8r]
        ]
      end
    end

    it "reach only the next onset in their own part" do
      subject = quantizer([*note(0, 80), *note(96, 192), *note(0, 80, channel: 1), *note(192, 288, channel: 1)])
      expect(spans(subject)).to eq [[0r, 1/4r], [0r, 3/16r], [1/4r, 1/2r], [1/2r, 3/4r]]
    end

    it "give a zero-length note one step" do
      subject = quantizer([*note(0, 64), *note(64, 128), *note(128, 192), *note(192, 192)])
      expect(spans(subject).last).to eq [1/2r, 1/2r + 1/24r]
    end
  end

  describe "grid:" do
    it "takes any Rational down to 1/1024 and refuses one finer" do
      expect(quantizer(note(0, 96), grid: 1/1024r).grid).to eq 1/1024r
      expect { quantizer(note(0, 96), grid: 1/2048r) }.to raise_error(ArgumentError, "grid: 1/2048 is finer than 1/1024")
    end

    it "refuses a grid that is not positive" do
      expect { quantizer(note(0, 96), grid: 0r) }.to raise_error(ArgumentError, "grid: takes :auto or a positive Rational, not (0/1)")
    end

    it "refuses a grid finer than 1/1024 from MIDI.parse" do
      expect { HeadMusic::MIDI.parse(HeadMusic::MIDI::SMF.file(division: division, tracks: [note(0, 96)]), grid: 1/2048r) }
        .to raise_error(ArgumentError, "grid: 1/2048 is finer than 1/1024")
    end
  end
end
