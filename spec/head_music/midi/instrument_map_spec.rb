require "spec_helper"

describe HeadMusic::MIDI::InstrumentMap do
  let(:catalog) do
    HeadMusic::Instruments::Instrument::INSTRUMENTS.keys
      .filter_map { |key| HeadMusic::Instruments::Instrument.get(key) }
      .uniq(&:name_key)
  end

  def ambiguous(attribute)
    catalog.select(&attribute).group_by(&attribute).select { |_, instruments| instruments.length > 1 }.keys.sort
  end

  describe ".instrument" do
    programs = {
      1 => :piano, 2 => nil, 3 => nil, 4 => nil, 5 => nil, 6 => nil, 7 => :harpsichord, 8 => :clavichord,
      9 => :celesta, 10 => :glockenspiel, 11 => nil, 12 => :vibraphone, 13 => :marimba, 14 => :xylophone,
      15 => :chimes, 16 => :hammered_dulcimer, 17 => nil, 18 => nil, 19 => nil, 20 => :organ, 21 => nil,
      22 => :accordion, 23 => :harmonica, 24 => nil, 25 => :guitar, 26 => :mandolin, 27 => nil, 28 => nil,
      29 => nil, 30 => nil, 31 => nil, 32 => nil, 33 => :bass_ukulele, 34 => :bass_guitar, 35 => nil,
      36 => nil, 37 => nil, 38 => nil, 39 => nil, 40 => nil, 41 => :violin, 42 => :viola, 43 => :cello,
      44 => :double_bass, 45 => nil, 46 => nil, 47 => :harp, 48 => :timpani, 49 => nil, 50 => nil,
      51 => nil, 52 => nil, 53 => :soprano_voice, 54 => nil, 55 => nil, 56 => nil, 57 => :trumpet,
      58 => :trombone, 59 => :tuba, 60 => nil, 61 => :french_horn, 62 => nil, 63 => nil, 64 => nil,
      65 => :soprano_saxophone, 66 => :alto_saxophone, 67 => :tenor_saxophone, 68 => :baritone_saxophone,
      69 => :oboe, 70 => :cor_anglais, 71 => :bassoon, 72 => :clarinet, 73 => :piccolo_flute, 74 => :flute,
      75 => :recorder, 76 => nil, 77 => nil, 78 => nil, 79 => nil, 80 => nil, 81 => :synthesizer,
      82 => nil, 83 => nil, 84 => nil, 85 => nil, 86 => nil, 87 => nil, 88 => nil, 89 => nil, 90 => nil,
      91 => nil, 92 => nil, 93 => nil, 94 => nil, 95 => nil, 96 => nil, 97 => nil, 98 => nil, 99 => nil,
      100 => nil, 101 => nil, 102 => nil, 103 => nil, 104 => nil, 105 => :sitar, 106 => :banjo,
      107 => nil, 108 => nil, 109 => nil, 110 => :great_highland_bagpipe, 111 => nil, 112 => nil,
      113 => nil, 114 => nil, 115 => :steelpan, 116 => nil, 117 => nil, 118 => nil, 119 => nil,
      120 => nil, 121 => nil, 122 => nil, 123 => nil, 124 => nil, 125 => nil, 126 => nil, 127 => nil,
      128 => nil
    }

    it "pins all 128 programs" do
      expect((1..128).to_h { |program| [program, described_class.instrument(program)&.name_key] }).to eq programs
    end

    it "pins exactly the programs the catalog shares among instruments" do
      expect(described_class::PINNED_PROGRAMS.keys.sort).to eq ambiguous(:gm_program)
    end

    it "pins each ambiguous program to an instrument with that program" do
      described_class::PINNED_PROGRAMS.each do |program, name_key|
        expect(HeadMusic::Instruments::Instrument.get(name_key).gm_program).to eq program
      end
    end

    context "with a hint" do
      it "takes the hinted instrument when it has the program" do
        expect(described_class.instrument(53, hint: "Alto").name_key).to eq :alto_voice
      end

      it "takes a hinted variant, which inherits its program" do
        expect(described_class.instrument(72, hint: "Clarinet in A").name_key).to eq :clarinet_in_a
      end

      it "takes a hint that has the program of a program with one instrument" do
        expect(described_class.instrument(66, hint: "alto saxophone").name_key).to eq :alto_saxophone
      end

      it "ignores a hinted instrument with another program" do
        expect(described_class.instrument(57, hint: "Violin").name_key).to eq :trumpet
      end

      it "ignores a hint that names no instrument" do
        expect(described_class.instrument(57, hint: "Track 1").name_key).to eq :trumpet
      end
    end
  end

  describe ".sound" do
    keys = {
      35 => :bass_drum, 36 => :bass_drum, 37 => nil, 38 => :snare_drum, 39 => nil, 40 => :snare_drum,
      41 => :floor_tom, 42 => :hi_hat, 43 => nil, 44 => :hi_hat, 45 => :tenor_drum, 46 => :hi_hat,
      47 => :mid_tom, 48 => nil, 49 => :crash_cymbal, 50 => :high_tom, 51 => :ride_cymbal, 52 => :tam_tam,
      53 => nil, 54 => :tambourine, 55 => nil, 56 => :cowbell, 57 => :crash_cymbal, 58 => nil,
      59 => :ride_cymbal, 60 => nil, 61 => nil, 62 => nil, 63 => nil, 64 => nil, 65 => nil, 66 => nil,
      67 => nil, 68 => nil, 69 => nil, 70 => :maracas, 71 => nil, 72 => nil, 73 => nil, 74 => nil,
      75 => nil, 76 => :woodblock, 77 => nil, 78 => nil, 79 => nil, 80 => nil, 81 => :triangle
    }

    it "pins keys 35 to 81" do
      expect((35..81).to_h { |key| [key, described_class.sound(key).name_key] }).to eq keys
    end

    it "has a pinned entry for every key the catalog shares among instruments" do
      expect(ambiguous(:gm_percussion_key) - described_class::PINNED_PERCUSSION_KEYS.keys).to eq []
    end

    it "takes the hinted instrument when it has the key" do
      expect(described_class.sound(49, hint: "suspended cymbal").name_key).to eq :suspended_cymbal
    end

    it "ignores a hinted instrument with another key" do
      expect(described_class.sound(49, hint: "snare drum").name_key).to eq :crash_cymbal
    end

    it "ignores a hint for an alias key, whose instrument names another key" do
      expect(described_class.sound(36, hint: "bass drum").name_key).to eq :bass_drum
    end
  end
end
