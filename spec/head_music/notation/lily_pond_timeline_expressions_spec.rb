require "spec_helper"

describe HeadMusic::Notation::LilyPond do
  def parse(music)
    described_class.parse(music)
  end

  def fermatas(flow)
    flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s] }
  end

  def ramps(flow)
    flow.tempo_ramps.map { |ramp| [ramp.from.to_s, ramp.to.to_s, ramp.to_tempo&.beats_per_minute, ramp.text] }
  end

  def bar_lines(rendered)
    rendered.lines.map(&:strip).select { |line| line.end_with?("|") || line.include?("\\bar") }
  end

  def abc(body, header: "M:4/4\nL:1/4\n")
    HeadMusic::Notation::ABC.parse("X:1\nT:Expressions\n#{header}K:C\n#{body}\n")
  end

  describe "reading \\tempo" do
    it "opens the flow at the first tempo, with its text" do
      flow = parse(%({ \\tempo "Allegro" 4 = 132 c'1 | }))
      expect([flow.tempo.beats_per_minute, flow.tempo.text, flow.tempo_changes]).to eq [132, "Allegro", {}]
    end

    it "changes the tempo at a downbeat" do
      flow = parse(%({ c'1 | \\tempo "Meno mosso" 4. = 50 c'1 | }))
      expect([flow.tempo_at(2).beat_value.to_s, flow.tempo_at(2).beats_per_minute, flow.tempo_at(2).text]).to eq ["dotted quarter", 50, "Meno mosso"]
    end

    it "does not change a tempo it restates" do
      expect(parse(%({ \\tempo 4 = 90 c'1 | \\tempo 4 = 90 c'1 | })).tempo_changes).to be_empty
    end

    it "reads tempo text in a markup" do
      expect(parse(%({ \\tempo \\markup { \\italic Adagio } c'1 | })).tempo.text).to eq "Adagio"
    end

    it "reads a \\tempo in a \\new Dynamics for its syntax alone" do
      source = %(\\new PianoStaff << \\new Staff { c''1 | } \\new Dynamics { \\tempo 4 = 60 \\numericTimeSignature s1 | } \\new Staff { c1 | } >>)
      expect(parse(source).tempo).to eq HeadMusic::Rudiment::Tempo.new("quarter", 120)
    end

    it "still skips a \\tempo inside a \\midi block" do
      expect(parse(%(\\score { { c'1 | } \\midi { \\tempo 4. = 60-66 } })).tempo).to eq HeadMusic::Rudiment::Tempo.new("quarter", 120)
    end
  end

  describe "reading time signatures" do
    def meters(flow)
      (1..flow.last_sounding_bar_number).map { |bar_number| [flow.meter_at(bar_number).to_s, flow.meter_at(bar_number).symbol] }
    end

    it "reads a plain 4/4 as common time and 2/2 as cut time, as LilyPond prints them" do
      expect(meters(parse("{ \\time 4/4 c'1 | \\time 2/2 c'1 | \\time 3/4 c'2. | }")))
        .to eq [["4/4", :common], ["2/2", :cut], ["3/4", nil]]
    end

    it "reads numerals after \\numericTimeSignature, and symbols again after \\defaultTimeSignature" do
      source = "{ \\numericTimeSignature \\time 4/4 c'1 | \\time 2/2 c'1 | \\defaultTimeSignature \\time 2/2 c'1 | }"
      expect(meters(parse(source))).to eq [["4/4", nil], ["2/2", nil], ["2/2", :cut]]
    end

    it "keeps a change of the symbol alone" do
      flow = parse("{ \\time 4/4 c'1 | \\numericTimeSignature \\time 4/4 c'1 | }")
      expect(flow.meter_changes.transform_values { |meter| [meter.to_s, meter.symbol] }).to eq(2 => ["4/4", nil])
    end

    it "carries a staff's style into the voice inside it" do
      expect(parse("\\new Staff { \\numericTimeSignature \\new Voice { \\time 4/4 c'1 | } }").meter.symbol).to be_nil
    end

    it "keeps the first staff's symbol where a second staff prints numerals" do
      source = "<< \\new Staff { \\time 4/4 c''1 | } \\new Staff { \\numericTimeSignature \\time 4/4 c'1 | } >>"
      expect(parse(source).meter.symbol).to eq :common
    end
  end

  describe "reading fermatas" do
    {
      "a note" => ["{ c'2 d'2\\fermata | }", [["1:3:000", "2:1:000"]]],
      "a rest" => ["{ c'2 r2\\fermata | }", [["1:3:000", "2:1:000"]]],
      "a whole-bar rest" => ["{ c'1 | R1\\fermata | }", [["2:1:000", "3:1:000"]]],
      "a chord" => ["{ <c' e'>1^\\fermata | }", [["1:1:000", "2:1:000"]]],
      "a long fermata" => ["{ c'1\\longfermata | }", [["1:1:000", "2:1:000"]]],
      "a tied note's later link" => ["{ c'2~ c'2\\fermata | }", [["1:3:000", "2:1:000"]]],
      "a tied note's first link" => ["{ c'2\\fermata~ c'2 | }", [["1:1:000", "2:1:000"]]]
    }.each do |description, (source, expected)|
      it "reads one on #{description}" do
        expect(fermatas(parse(source))).to eq expected
      end
    end

    it "makes one fermata of marks that sound together, where all of them sound" do
      source = "<< \\new Staff { d''4 cis''4\\fermata b'2 | } \\new Staff { b4 g8 a8\\fermata g2 | } >>"
      expect(fermatas(parse(source))).to eq [["1:2:480", "1:3:000"]]
    end
  end

  describe "reading tempo words in annotations" do
    it "reads a ramp to the next tempo" do
      expect(ramps(parse(%({ c'2 c'2^"rit." | \\tempo 4 = 60 c'1 | })))).to eq [["1:3:000", "2:1:000", 60, "rit."]]
    end

    it "reads a ramp and an \"a tempo\" from markups" do
      flow = parse(%({ c'2 c'2^\\markup { \\italic poco rit. } | c'1_\\markup \\italic "a tempo" | }))
      expect([ramps(flow), flow.a_tempos.map { |a_tempo| [a_tempo.position.to_s, a_tempo.text] }])
        .to eq [[["1:3:000", "2:1:000", nil, "poco rit."]], [["2:1:000", "a tempo"]]]
    end

    it "reads a ramp starting inside a note through \\after" do
      expect(ramps(parse(%({ \\after 2 ^"accel." c'1 | c'1 | })))).to eq [["1:3:000", "3:1:000", nil, "accel."]]
    end

    it "reads a ramp from a tied note's later link" do
      expect(ramps(parse(%({ c'2~ c'2^"rit." | c'1 | })))).to eq [["1:3:000", "3:1:000", nil, "rit."]]
    end

    it "reads a ramp written in a \\new Dynamics" do
      source = %(\\new PianoStaff << \\new Staff { c''1 | c''1 | } \\new Dynamics { s2 s2^"rit." | s1 | } \\new Staff { c1 | c1 | } >>)
      expect(ramps(parse(source))).to eq [["1:3:000", "3:1:000", nil, "rit."]]
    end

    it "drops other annotation text instead of raising" do
      flow = parse(%({ c'1^"dolce" | c'1_\\markup { \\bold "cantabile" } | }))
      expect([flow.tempo_ramps, flow.a_tempos, flow.voices.first.voice_events.length]).to eq [[], [], 2]
    end
  end

  describe "writing" do
    let(:rendered) { described_class.render(flow) }

    context "with tempos" do
      let(:flow) do
        abc(%(C D E F|[Q:"Più mosso" 3/8=80]G A B c|[Q:1/2=60]c4|), header: %(M:4/4\nL:1/4\nQ:"Adagio"\nV:1\nV:2\n)).tap do |flow|
          flow.voices.last.place("1:1", :whole, "C3")
        end
      end

      it "writes each tempo in the first voice only" do
        expect(rendered.scan(/\\tempo.*?(?= [a-gr]|\n)/)).to eq [%(\\tempo "Adagio"), %(\\tempo "Più mosso" 4. = 80), "\\tempo 2 = 60"]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    it "writes no \\tempo for the tempo a flow reads at when none is written" do
      expect(described_class.render(abc("C D E F|"))).not_to include "\\tempo"
    end

    it "raises for a fractional tempo" do
      flow = HeadMusic::Content::Flow.new(tempo: HeadMusic::Rudiment::Tempo.new("quarter", 72.5)).tap { |built| built.add_voice.place("1:1", :whole, "C4") }
      expect { described_class.render(flow) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /fractional tempo of 72.5 beats per minute/)
    end

    it "raises for a ramp it would not read back" do
      flow = abc("C D E F|G A B c|").tap { |built| built.add_tempo_ramp(from: "1:3", to: "2:1", text: "morendo") }
      expect { described_class.render(flow) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /tempo ramp from 1:3:000 to 2:1:000 .* so that it reads back/)
    end

    it "raises for a tempo where no note of the first voice starts" do
      flow = abc("C4|C4|").tap { |built| built.add_tempo_ramp(from: "1:1", to: "1:3", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 60)) }
      expect { described_class.render(flow) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /tempo ramp end at 1:3:000 .* where no note of the first voice starts/)
    end

    context "with time signatures" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |built|
          voice = built.add_voice
          [[1, :whole], [2, :whole], [3, :"dotted half"], [4, :whole], [5, :whole]].each { |bar, value| voice.place("#{bar}:1", value, "C4") }
          built.change_meter(2, HeadMusic::Rudiment::Meter.common_time)
          built.change_meter(3, "3/4")
          built.change_meter(4, "2/2")
          built.change_meter(5, HeadMusic::Rudiment::Meter.cut_time)
        end
      end

      it "asks for numerals before a 4/4 or 2/2 with no symbol, and for symbols when one returns" do
        expect(rendered.lines.map(&:strip).grep(/\\time/).map { |line| line[/\A.*\\time \S+/] }).to eq [
          "\\numericTimeSignature \\time 4/4", "\\defaultTimeSignature \\time 4/4", "\\time 3/4",
          "\\numericTimeSignature \\time 2/2", "\\defaultTimeSignature \\time 2/2"
        ]
      end

      it "reads back each meter and symbol" do
        expect(described_class.parse(rendered).meter_changes.transform_values { |meter| [meter.to_s, meter.symbol] })
          .to eq(2 => ["4/4", :common], 3 => ["3/4", nil], 4 => ["2/2", nil], 5 => ["2/2", :cut])
      end

      it "writes the style on a staff nobody is written on" do
        flow.add_part
        expect(bar_lines(rendered).last(5)).to eq ["R1*4/4 |", "\\defaultTimeSignature R1*4/4 |", "R1*3/4 |", "\\numericTimeSignature R1*2/2 |", "\\defaultTimeSignature R1*2/2 |"]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    it "writes no style command for a common-time flow" do
      rendered = described_class.render(abc("C D E F|", header: "M:C\nL:1/4\n"))
      expect([rendered.include?("\\time 4/4\n"), rendered.include?("TimeSignature")]).to eq [true, false]
    end

    context "with a fermata whose carriers began earlier" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |built|
          built.add_voice.place("1:1", :breve, "C5")
          built.add_voice.place("1:1", :whole, "C4").voice.place("2:1", :quarter, "D4").voice.place("2:2", :"dotted half")
          built.add_fermata("2:1", :quarter)
        end
      end

      it "marks the link of each sounding there, rests and tied notes included" do
        expect(bar_lines(rendered)).to eq ["c''1~ |", "c''1\\fermata \\bar \"|.\" |", "c'1 |", "d'4\\fermata r2. \\bar \"|.\" |"]
      end

      it "reads back the fermata where it began" do
        expect(fermatas(described_class.parse(rendered))).to eq [["2:1:000", "2:2:000"]]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end

    context "with a ramp starting inside a note and ending on the final barline" do
      let(:flow) do
        abc("C3 D|E4|").tap do |built|
          built.add_tempo_ramp(from: "1:2", to: "3:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 60), text: "rall.")
        end
      end

      it "writes its words with \\after and its target after the music" do
        expect(bar_lines(rendered)).to eq [%(\\after 4 ^\\markup \\italic "rall." c'2. d'4 |), %(e'1 \\tempo 4 = 60 \\bar "|." |)]
      end

      it "reads it back" do
        expect(ramps(described_class.parse(rendered))).to eq [["1:2:000", "3:1:000", 60, "rall."]]
      end

      it "compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond

        expect(compile_warnings(rendered)).to be_empty
      end
    end
  end

  describe "round trips" do
    {"the melody" => :melody, "the chorale" => :chorale}.each do |description, fixture|
      context "with #{description}" do
        let(:original) { TimelineExpressionFixtures.public_send(fixture) }
        let(:rendered) { described_class.render(original) }
        let(:round_tripped) { described_class.parse(rendered) }

        # LilyPond writes no fermata's stretch.
        it "keeps the tempos, meters, ramps, \"a tempo\" points, and fermatas" do
          expect_same_timeline(original, round_tripped, except: %i[stretch])
        end

        it "writes back what it wrote" do
          expect(described_class.render(round_tripped)).to eq rendered
        end

        it "compiles without warnings" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_warnings(rendered)).to be_empty
        end
      end
    end
  end

  context "with a tied note held under two fermatas" do
    let(:original) { TimelineExpressionFixtures.tied_under_two_fermatas }
    let(:rendered) { described_class.render(original) }

    # LilyPond writes no fermata's stretch.
    it "keeps both fermatas" do
      expect_same_timeline(original, described_class.parse(rendered), except: %i[stretch])
    end

    it "compiles without warnings" do
      skip "lilypond is not installed" unless installed_lilypond

      expect(compile_warnings(rendered)).to be_empty
    end
  end
end
