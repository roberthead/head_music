require "spec_helper"

describe HeadMusic::Time::SmpteTimecode do
  describe ".parse" do
    subject(:timecode) { described_class.parse(identifier) }

    context "with standard format '01:00:00:00'" do
      let(:identifier) { "01:00:00:00" }

      its(:hour) { is_expected.to eq 1 }
      its(:minute) { is_expected.to eq 0 }
      its(:second) { is_expected.to eq 0 }
      its(:frame) { is_expected.to eq 0 }
    end

    context "with '02:30:45:15'" do
      let(:identifier) { "02:30:45:15" }

      its(:hour) { is_expected.to eq 2 }
      its(:minute) { is_expected.to eq 30 }
      its(:second) { is_expected.to eq 45 }
      its(:frame) { is_expected.to eq 15 }
    end

    context "with partial timecodes" do
      context "with '05:30'" do
        let(:identifier) { "05:30" }

        its(:hour) { is_expected.to eq 5 }
        its(:minute) { is_expected.to eq 30 }
        its(:second) { is_expected.to eq 0 }
        its(:frame) { is_expected.to eq 0 }
      end

      context "with '01:15:30'" do
        let(:identifier) { "01:15:30" }

        its(:hour) { is_expected.to eq 1 }
        its(:minute) { is_expected.to eq 15 }
        its(:second) { is_expected.to eq 30 }
        its(:frame) { is_expected.to eq 0 }
      end
    end
  end

  describe "#initialize" do
    subject(:timecode) { described_class.new(hour, minute, second, frame) }

    context "with default parameters" do
      subject(:timecode) { described_class.new }

      its(:hour) { is_expected.to eq 0 }
      its(:minute) { is_expected.to eq 0 }
      its(:second) { is_expected.to eq 0 }
      its(:frame) { is_expected.to eq 0 }
      its(:framerate) { is_expected.to eq 30 }
    end

    context "with specific values" do
      let(:hour) { 2 }
      let(:minute) { 15 }
      let(:second) { 30 }
      let(:frame) { 12 }

      its(:hour) { is_expected.to eq 2 }
      its(:minute) { is_expected.to eq 15 }
      its(:second) { is_expected.to eq 30 }
      its(:frame) { is_expected.to eq 12 }
    end

    context "with string parameters" do
      let(:hour) { "3" }
      let(:minute) { "45" }
      let(:second) { "22" }
      let(:frame) { "18" }

      it "converts strings to integers" do
        expect(timecode.hour).to eq 3
        expect(timecode.minute).to eq 45
        expect(timecode.second).to eq 22
        expect(timecode.frame).to eq 18
      end
    end

    context "with custom framerate" do
      subject(:timecode) { described_class.new(1, 0, 0, 0, framerate: 24) }

      its(:framerate) { is_expected.to eq 24 }
    end
  end

  describe "#to_s" do
    subject(:timecode) { described_class.new(2, 30, 45, 15) }

    it "returns formatted string with zero padding" do
      expect(timecode.to_s).to eq "02:30:45:15"
    end

    context "with single digit values" do
      subject(:timecode) { described_class.new(1, 5, 3, 9) }

      it "pads with zeros" do
        expect(timecode.to_s).to eq "01:05:03:09"
      end
    end
  end

  describe "#to_a" do
    subject(:timecode) { described_class.new(2, 30, 45, 15) }

    it "returns array of components" do
      expect(timecode.to_a).to eq [2, 30, 45, 15]
    end
  end

  describe "#normalize!" do
    context "with 30 fps framerate" do
      subject(:timecode) { described_class.new(0, 0, 0, 0, framerate: 30) }

      context "with overflow in frames" do
        subject(:timecode) { described_class.new(0, 0, 0, 30, framerate: 30) }

        it "carries frames into seconds" do
          timecode.normalize!
          expect(timecode.hour).to eq 0
          expect(timecode.minute).to eq 0
          expect(timecode.second).to eq 1
          expect(timecode.frame).to eq 0
        end

        it "returns self" do
          expect(timecode.normalize!).to be timecode
        end
      end

      context "with overflow in seconds" do
        subject(:timecode) { described_class.new(0, 0, 60, 0, framerate: 30) }

        it "carries seconds into minutes" do
          timecode.normalize!
          expect(timecode.hour).to eq 0
          expect(timecode.minute).to eq 1
          expect(timecode.second).to eq 0
          expect(timecode.frame).to eq 0
        end
      end

      context "with overflow in minutes" do
        subject(:timecode) { described_class.new(0, 60, 0, 0, framerate: 30) }

        it "carries minutes into hours" do
          timecode.normalize!
          expect(timecode.hour).to eq 1
          expect(timecode.minute).to eq 0
          expect(timecode.second).to eq 0
          expect(timecode.frame).to eq 0
        end
      end

      context "with multiple levels of overflow" do
        subject(:timecode) { described_class.new(0, 0, 0, 90, framerate: 30) }

        it "normalizes all levels" do
          timecode.normalize!
          expect(timecode.hour).to eq 0
          expect(timecode.minute).to eq 0
          expect(timecode.second).to eq 3
          expect(timecode.frame).to eq 0
        end
      end
    end

    context "with 24 fps framerate" do
      context "with overflow in frames" do
        subject(:timecode) { described_class.new(0, 0, 0, 48, framerate: 24) }

        it "carries frames into seconds with 24 fps" do
          timecode.normalize!
          expect(timecode.hour).to eq 0
          expect(timecode.minute).to eq 0
          expect(timecode.second).to eq 2
          expect(timecode.frame).to eq 0
        end
      end
    end

    context "with negative values" do
      subject(:timecode) { described_class.new(1, 0, 0, -5, framerate: 30) }

      it "handles negative frame overflow" do
        timecode.normalize!
        expect(timecode.hour).to eq 0
        expect(timecode.minute).to eq 59
        expect(timecode.second).to eq 59
        expect(timecode.frame).to eq 25
      end
    end
  end

  describe "Comparable" do
    let(:one_hour) { described_class.new(1, 0, 0, 0, framerate: 30) }
    let(:one_hour_thirty_seconds) { described_class.new(1, 0, 30, 0, framerate: 30) }
    let(:also_one_hour) { described_class.new(1, 0, 0, 0, framerate: 30) }
    let(:two_hours) { described_class.new(2, 0, 0, 0, framerate: 30) }

    before do
      one_hour.normalize!
      one_hour_thirty_seconds.normalize!
      also_one_hour.normalize!
      two_hours.normalize!
    end

    it "compares timecodes correctly" do
      expect(one_hour).to eq also_one_hour
      expect(one_hour).to be < one_hour_thirty_seconds
      expect(one_hour_thirty_seconds).to be > one_hour
      expect(one_hour_thirty_seconds).to be < two_hours
    end

    it "supports between?" do
      expect(one_hour_thirty_seconds).to be_between(one_hour, two_hours)
    end

    context "with frame differences" do
      let(:tc_a) { described_class.new(1, 0, 0, 0, framerate: 30) }
      let(:tc_b) { described_class.new(1, 0, 0, 15, framerate: 30) }

      before do
        tc_a.normalize!
        tc_b.normalize!
      end

      it "compares by frame values" do
        expect(tc_a).to be < tc_b
      end
    end
  end

  describe "#to_total_frames" do
    context "with 30 fps" do
      subject(:timecode) { described_class.new(0, 1, 30, 15, framerate: 30) }

      it "converts to total frames" do
        # 1 minute = 1800 frames, 30 seconds = 900 frames, 15 frames
        expect(timecode.to_total_frames).to eq 2715
      end
    end

    context "with 24 fps" do
      subject(:timecode) { described_class.new(1, 0, 0, 0, framerate: 24) }

      it "converts to total frames" do
        # 1 hour at 24 fps = 86400 frames
        expect(timecode.to_total_frames).to eq 86400
      end
    end
  end
end
