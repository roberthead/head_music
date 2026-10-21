require "spec_helper"

# Fermatas, common- and cut-time signs, and tempo words through kern, which
# holds several voices but has no ramps and no way to write a fermata's
# stretch.
describe HeadMusic::Notation::Kern do
  # Columns are separated by two or more spaces, so that chords can keep
  # their single spaces.
  def parse(text)
    described_class.parse(text.gsub(/ {2,}/, "\t"))
  end

  # The rows of the spines' music, after their headers and before their
  # final barline and terminators.
  def spines(count, *rows)
    columns = ->(field) { ([field] * count).join("  ") }
    parse([columns["**kern"], *rows, columns["=="], columns["*-"]].join("\n") + "\n")
  end

  def fermatas(flow)
    flow.fermatas.map { |fermata| "#{fermata.from} to #{fermata.to}" }
  end

  def meter_changes(flow)
    flow.meter_changes.transform_values { |meter| [meter.to_s, meter.symbol] }
  end

  def tempo_summary(tempo)
    [tempo.text, tempo.metronome_mark?, tempo.beats_per_minute]
  end

  def round_trip(flow)
    described_class.parse(described_class.render(flow))
  end

  describe "reading fermatas" do
    it "reads ; on a note, a rest, a chord, and hidden as ;y into timeline fermatas" do
      flow = spines(1, "*M3/4", "=1", "4c;", "4r;", "4c 4e;", "=2", "2.c;y")
      expect(fermatas(flow)).to eq ["1:1:000 to 1:2:000", "1:2:000 to 1:3:000", "1:3:000 to 2:1:000", "2:1:000 to 3:1:000"]
    end

    it "holds the whole flow for a fermata marked in one spine only" do
      expect(fermatas(spines(2, "*M2/4  *M2/4", "=1  =1", "2C  4c", ".  4d;"))).to eq ["1:2:000 to 2:1:000"]
    end

    it "joins marks that sound together into one fermata, from the latest start to the earliest end" do
      expect(fermatas(spines(2, "*M2/4  *M2/4", "=1  =1", "4C  8c", ".  8d;", "4D;  4e;"))).to eq ["1:1:480 to 1:2:000", "1:2:000 to 2:1:000"]
    end

    it "holds a fermata on a tie's later link from that link" do
      expect(fermatas(spines(1, "*M2/4", "=1", "[2c", "=2", "4c];", "4d"))).to eq ["2:1:000 to 2:2:000"]
    end

    it "drops a fermata on a grace note, which takes no time" do
      expect(spines(1, "*M2/4", "8qd;", "2c").fermatas).to be_empty
    end
  end

  describe "writing fermatas" do
    it "marks every voice event sounding where a fermata begins, in every voice" do
      kern = described_class.render(TimelineExpressionFixtures.chorale)
      expect(kern.lines.map(&:chomp)).to include("8G\t4cc#;", "8A;\t.", "2D;\t2dd;")
    end

    it "marks a rest" do
      expect(described_class.render(TimelineExpressionFixtures.melody).lines.map(&:chomp)).to include "2r;"
    end

    it "marks each link of a tied note on which a fermata begins" do
      flow = spines(2, "*M2/4  *M2/4", "=1  =1", "2G;  [2c;", "=2  =2", "2A;  4c];", ".  4d")
      expect([fermatas(round_trip(flow)), fermatas(flow)]).to eq [["1:1:000 to 2:1:000", "2:1:000 to 2:2:000"]] * 2
    end
  end

  describe "meter signs" do
    def meter_flow(opening, change = "*")
      spines(1, opening, "=1", "1c", "=2", change, "1d")
    end

    it "reads *met(c) as common time" do
      expect(meter_flow("*M4/4\n*met(c)").meter.symbol).to eq :common
    end

    it "reads *met(c|) as cut time, whichever row comes first" do
      expect(meter_flow("*met(c|)\n*M2/2").meter.symbol).to eq :cut
    end

    it "ignores a sign drawing a meter other than the one beside it" do
      flow = spines(1, "*M3/4", "*met(c)", "2.c")
      expect([flow.meter.to_s, flow.meter.symbol]).to eq ["3/4", nil]
    end

    it "reads a change of sign alone as a meter change" do
      expect(meter_changes(meter_flow("*M4/4", "*met(c)"))).to eq(2 => ["4/4", :common])
    end

    it "reads a restated meter and sign as no change" do
      expect(meter_changes(meter_flow("*M4/4\n*met(c)", "*M4/4\n*met(c)"))).to be_empty
    end

    it "reads a numeric meter after common time as a change" do
      expect(meter_changes(meter_flow("*M4/4\n*met(c)", "*M4/4"))).to eq(2 => ["4/4", nil])
    end

    context "with common time changing to numeric 4/4" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: HeadMusic::Rudiment::Meter.common_time).tap do |flow|
          flow.change_meter(2, "4/4")
          voice = flow.add_voice
          voice.place("1:1", :whole, "C4")
          voice.place("2:1", :whole, "D4")
        end
      end

      it "writes *met(c) after the opening *M4/4 only" do
        kern = described_class.render(flow)
        expect([kern.scan(%r{^\*M4/4\n\*met\(c\)$}).length, kern.scan(%r{^\*M4/4$}).length]).to eq [1, 2]
      end

      it "reads back the change of sign alone" do
        expect(meter_changes(round_trip(flow))).to eq(2 => ["4/4", nil])
      end
    end
  end

  describe "tempo words" do
    def tempo_flow(opening, change = "*", reference: nil)
      parse([reference, "**kern", "*M2/4", opening, "=1", "2c", "=2", change, "2d", "==", "*-"].compact.join("\n") + "\n")
    end

    it "reads !!!OMD as the opening tempo's words" do
      expect(tempo_summary(tempo_flow("*MM132", reference: "!!!OMD: Allegro").tempo)).to eq ["Allegro", true, 132.0]
    end

    it "reads !!!OMD with no *MM as a tempo whose number was not written" do
      expect(tempo_summary(tempo_flow("*", reference: "!!!OMD: Adagio").tempo)).to eq ["Adagio", false, 60.0]
    end

    it "reads a !!!OMD after the music starts as no tempo" do
      flow = spines(1, "*MM100", "4c", "!!!OMD: Presto", "4d")
      expect([tempo_summary(flow.tempo), flow.tempo_changes]).to eq [[nil, true, 100.0], {}]
    end

    it "reads *MM[Andante] as a tempo of words alone" do
      expect(tempo_summary(tempo_flow("*MM[Andante]").tempo)).to eq ["Andante", false, 78.0]
    end

    it "reads a tempo's words and number, on rows of their own, as one change" do
      flow = tempo_flow("*MM100", "*MM[Più mosso]\n*MM132")
      expect(flow.tempo_changes.transform_values { |tempo| tempo_summary(tempo) }).to eq(2 => ["Più mosso", true, 132.0])
    end

    it "reads a change of words alone as a tempo change" do
      flow = tempo_flow("*MM[Andante]\n*MM80", "*MM[Allegro]\n*MM80")
      expect(flow.tempo_changes.transform_values(&:text)).to eq(2 => "Allegro")
    end

    it "reads a restated tempo, words and number, as no change" do
      expect(tempo_flow("*MM[Andante]\n*MM80", "*MM[Andante]\n*MM80").tempo_changes).to be_empty
    end

    it "reads no ramp, and no tempo, from ramp words" do
      flow = tempo_flow("*MM100", "*MM[rit.]")
      expect([flow.tempo_changes, flow.tempo_ramps, flow.a_tempos]).to eq [{}, [], []]
    end

    it "writes the opening tempo's words as !!!OMD and leaves out a number that was not written" do
      flow = HeadMusic::Content::Flow.new(tempo: HeadMusic::Rudiment::Tempo.for_text("Adagio"))
      flow.add_voice.place("1:1", :whole, "C4")
      kern = described_class.render(flow)
      expect([kern.lines.first.chomp, kern.include?("*MM")]).to eq ["!!!OMD: Adagio", false]
    end

    it "writes a later tempo's words before its number" do
      kern = described_class.render(TimelineExpressionFixtures.melody)
      expect(kern).to include "=3\n*MM[Meno mosso]\n*MM96\n"
    end
  end

  describe "ramps" do
    let(:melody) { TimelineExpressionFixtures.melody }

    it "writes a flow with ramps at the tempo authored for each bar" do
      expect(described_class.render(melody).scan(/^=(\d+)\n((?:\*MM.*\n)+)/))
        .to eq [["3", "*MM[Meno mosso]\n*MM96\n"], ["4", "*MM72\n"], ["5", "*MM[Meno mosso]\n*MM96\n"]]
    end

    it "reads back no ramps or \"a tempo\" points" do
      expect([round_trip(melody).tempo_ramps, round_trip(melody).a_tempos]).to eq [[], []]
    end
  end

  # Kern writes no ramps. It writes no fermata's stretch either, but these
  # fermatas have the default stretch, which is what comes back. The
  # chorale's *MM counts quarter notes where its tempo counted half notes.
  describe "round trips of the timeline expression fixtures" do
    it "keeps the melody's timeline" do
      original = TimelineExpressionFixtures.melody
      expect_same_timeline(original, round_trip(original), except: %i[ramps])
    end

    it "keeps the chorale's timeline, counting quarter notes" do
      original = TimelineExpressionFixtures.chorale
      expect_same_timeline(original, round_trip(original), except: %i[ramps beat_values])
    end
  end
end
