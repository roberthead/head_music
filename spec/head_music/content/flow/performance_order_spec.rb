require "spec_helper"

describe HeadMusic::Content::Flow::PerformanceOrder do
  subject(:played) { flow.performance_order }

  let(:flow) { HeadMusic::Content::Flow.new }

  def bar(number)
    flow.bars(number).last
  end

  def jump(kind, to: nil)
    HeadMusic::Content::Jump.new(kind, to: to)
  end

  def numbers
    played.map(&:number)
  end

  def passes
    played.map(&:pass)
  end

  context "with no markings" do
    before { flow.add_voice.place("3:1:000", :whole, "C4") }

    it "plays the bars as written" do
      expect(numbers).to eq [1, 2, 3]
    end

    it "plays each bar once, on the first pass" do
      expect(played.map { |played_bar| [played_bar.pass, played_bar.playing] }.uniq).to eq [[1, 1]]
    end
  end

  context "with the D.S. al Fine of the story's example" do
    before do
      bar(8).barline = :double
      bar(9).rehearsal_mark = "B"
      bar(9).segno = true
      bar(16).jump = jump(:dal_segno, to: :fine)
      bar(12).fine = true
    end

    it "plays through, then from the segno to the Fine" do
      expect(numbers).to eq [*1..16, 9, 10, 11, 12]
    end

    it "counts each bar's playings" do
      expect(played.last).to have_attributes(number: 12, pass: 1, playing: 2)
    end

    it "is not memoized, so a changed bar changes the order" do
      flow.performance_order
      bar(10).fine = true
      bar(12).fine = false
      expect(flow.performance_order.last.number).to eq 10
    end
  end

  context "with a simple repeat" do
    before do
      bar(2).starts_repeat = true
      bar(3).ends_repeat_after_num_plays = 2
      bar(4).barline = :final
    end

    it "plays the repeated bars twice" do
      expect(numbers).to eq [1, 2, 3, 2, 3, 4]
    end

    it "numbers the passes" do
      expect(passes).to eq [1, 1, 1, 2, 2, 1]
    end
  end

  context "with a repeat played three times" do
    before do
      bar(1).starts_repeat = true
      bar(2).ends_repeat_after_num_plays = 3
    end

    it "plays the section three times" do
      expect(numbers).to eq [1, 2, 1, 2, 1, 2]
    end
  end

  context "with 1st and 2nd endings" do
    before do
      bar(1).starts_repeat = true
      bar(2).plays_on_passes = [1]
      bar(2).ends_repeat_after_num_plays = 2
      bar(3).plays_on_passes = [2]
      bar(4).fine = true
    end

    it "plays each ending on its pass" do
      expect(numbers).to eq [1, 2, 1, 3, 4]
    end
  end

  context "with an ending that names a third pass" do
    before do
      bar(1).starts_repeat = true
      bar(2).plays_on_passes = [1, 2]
      bar(2).ends_repeat_after_num_plays = 2
      bar(3).plays_on_passes = [3]
    end

    it "repeats until the highest pass" do
      expect(numbers).to eq [1, 2, 1, 2, 1, 3]
    end
  end

  context "with closing repeats and no opening repeat" do
    before do
      bar(2).ends_repeat_after_num_plays = 2
      bar(4).ends_repeat_after_num_plays = 2
    end

    it "goes back to the first bar, then to the bar after the previous closing repeat" do
      expect(numbers).to eq [1, 2, 1, 2, 3, 4, 3, 4]
    end
  end

  context "with a pickup bar and a D.C." do
    before do
      flow.add_voice.place("0:4:000", :quarter, "G4")
      bar(2).jump = jump(:da_capo)
    end

    it "returns to the pickup" do
      expect(numbers).to eq [0, 1, 2, 0, 1, 2]
    end
  end

  context "with a D.C. al Fine over a repeat with endings" do
    before do
      bar(1).starts_repeat = true
      bar(2).plays_on_passes = [1]
      bar(2).ends_repeat_after_num_plays = 2
      bar(3).plays_on_passes = [2]
      bar(3).fine = true
      bar(5).jump = jump(:da_capo, to: :fine)
    end

    it "does not repeat again and plays the last ending" do
      expect(numbers).to eq [1, 2, 1, 3, 4, 5, 1, 3]
    end

    it "plays the replayed section on its last pass" do
      expect(passes.last(2)).to eq [2, 2]
    end

    it "ignores the Fine before the jump" do
      expect(numbers.count(4)).to eq 1
    end
  end

  context "with a D.S. al Coda" do
    before do
      bar(2).segno = true
      bar(3).to_coda = true
      bar(4).jump = jump(:dal_segno, to: :coda)
      bar(5).coda = true
      bar(6).coda = true
    end

    it "takes the To Coda only after the jump, to the first coda sign after it" do
      expect(numbers).to eq [1, 2, 3, 4, 2, 3, 5, 6]
    end
  end

  context "with a plain D.C." do
    before do
      bar(2).fine = true
      bar(3).to_coda = true
      bar(4).jump = jump(:da_capo)
      bar(5).coda = true
    end

    it "stops at the Fine when it comes before the To Coda" do
      expect(numbers).to eq [1, 2, 3, 4, 1, 2]
    end
  end

  context "with a plain D.S. that reaches a To Coda first" do
    before do
      bar(1).segno = true
      bar(2).to_coda = true
      bar(3).fine = true
      bar(4).jump = jump(:dal_segno)
      bar(5).coda = true
    end

    it "goes to the coda" do
      expect(numbers).to eq [1, 2, 3, 4, 1, 2, 5]
    end
  end

  context "with a D.C. al Coda and a Fine along the way" do
    before do
      bar(1).fine = true
      bar(2).to_coda = true
      bar(3).jump = jump(:da_capo, to: :coda)
      bar(4).coda = true
    end

    it "ignores the Fine" do
      expect(numbers).to eq [1, 2, 3, 1, 2, 4]
    end
  end

  context "with a Fine on the jump bar" do
    before do
      bar(3).fine = true
      bar(3).jump = jump(:da_capo, to: :fine)
    end

    it "takes the jump, then stops at the Fine" do
      expect(numbers).to eq [1, 2, 3, 1, 2, 3]
    end
  end

  context "with a repeat on the jump bar" do
    before do
      bar(1).segno = true
      bar(2).ends_repeat_after_num_plays = 2
      bar(2).jump = jump(:dal_segno)
    end

    it "repeats first, then jumps, and does not jump again" do
      expect(numbers).to eq [1, 2, 1, 2, 1, 2]
    end
  end

  describe "navigation it cannot follow" do
    it "raises on a second jump" do
      bar(2).jump = jump(:da_capo)
      bar(4).jump = jump(:da_capo)
      expect { played }.to raise_error(ArgumentError, /bars 2, 4/)
    end

    it "raises on a D.S. with no segno before it" do
      bar(2).jump = jump(:dal_segno)
      bar(3).segno = true
      expect { played }.to raise_error(ArgumentError, /no segno/)
    end

    it "raises on an al Fine with no Fine" do
      bar(2).jump = jump(:da_capo, to: :fine)
      expect { played }.to raise_error(ArgumentError, /no Fine/)
    end

    it "raises on an al Coda with no To Coda before the jump" do
      bar(2).jump = jump(:da_capo, to: :coda)
      bar(3).to_coda = true
      bar(4).coda = true
      expect { played }.to raise_error(ArgumentError, /no To Coda/)
    end

    it "raises on an al Coda with no coda sign" do
      bar(1).to_coda = true
      bar(2).jump = jump(:da_capo, to: :coda)
      expect { played }.to raise_error(ArgumentError, /no coda sign/)
    end

    it "raises on a plain jump whose To Coda has no coda sign" do
      bar(1).to_coda = true
      bar(2).jump = jump(:da_capo)
      expect { played }.to raise_error(ArgumentError, /no coda sign/)
    end
  end
end
