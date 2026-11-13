require "spec_helper"

describe HeadMusic::Notation::MusicXML::IdentityReader do
  def flow_with(header, names: nil, part_list: nil)
    xml = musicxml_measures(note_xml("C4", 4, "whole"), header: header, names: names)
    xml = xml.sub(%r{<part-list>.*</part-list>}m, part_list) if part_list
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  let(:composer) { %(<identification><creator type="composer">Clara Schumann</creator><creator type="arranger">Someone</creator></identification>) }

  describe "titles" do
    it "names the flow for its work title alone, with no Work" do
      flow = flow_with("<work><work-title>Romance</work-title></work>")
      expect([flow.name, flow.work]).to eq ["Romance", nil]
    end

    it "names the flow for its movement title, and makes the work title its Work" do
      flow = flow_with("<work><work-title>Three Romances</work-title></work><movement-title>Andante</movement-title>")
      expect([flow.name, flow.work.title]).to eq ["Andante", "Three Romances"]
    end

    it "names the flow for its movement title alone" do
      expect(flow_with("<movement-title>Andante</movement-title>").name).to eq "Andante"
    end

    it "names the flow for a title credit when nothing else does" do
      credit = "<credit page=\"1\"><credit-type>title</credit-type><credit-words>Nocturne</credit-words></credit>"
      expect(flow_with(credit).name).to eq "Nocturne"
    end

    it "prefers the work title to a title credit" do
      credit = "<credit page=\"1\"><credit-type>title</credit-type><credit-words>Nocturne</credit-words></credit>"
      expect(flow_with("<work><work-title>Romance</work-title></work>#{credit}").name).to eq "Romance"
    end

    it "takes the default name where there is no title" do
      expect(flow_with("").name).to eq HeadMusic::Content::Flow::DEFAULT_NAME
    end
  end

  describe "composers" do
    it "gives a flow with no Work the composer string" do
      expect(flow_with("<work><work-title>Romance</work-title></work>#{composer}").composer).to eq "Clara Schumann"
    end

    it "credits the composer on the Work" do
      flow = flow_with("<work><work-title>Three Romances</work-title></work><movement-title>Andante</movement-title>#{composer}")
      expect(flow.work.credits.names(:composer)).to eq ["Clara Schumann"]
    end

    it "joins several composers" do
      creators = %(<identification><creator type="composer">A</creator><creator type="composer">B</creator></identification>)
      expect(flow_with(creators).composer).to eq "A, B"
    end

    it "skips the arranger" do
      arranger = %(<identification><creator type="arranger">Someone</creator></identification>)
      expect(flow_with(arranger).composer).to be_nil
    end
  end

  describe "parts" do
    it "names each part's player for its part name, with no project" do
      player = flow_with("", names: ["Violin"]).parts.first.player
      expect([player.name, player.project]).to eq ["Violin", nil]
    end

    it "gives a part with no part name no player" do
      expect(flow_with("", names: [nil]).parts.first.player).to be_nil
    end

    it "maps the instrument sound to a catalog instrument" do
      part_list = %(<part-list><score-part id="P1"><part-name>Cl.</part-name><score-instrument id="P1-I1">) +
        %(<instrument-name>Clarinet</instrument-name><instrument-sound>wind.reed.clarinet.bflat</instrument-sound></score-instrument></score-part></part-list>)
      expect(flow_with("", part_list: part_list).parts.first.instrument.name_key).to eq :clarinet
    end

    it "gives an unmapped sound no instrument" do
      part_list = %(<part-list><score-part id="P1"><part-name>Voice</part-name><score-instrument id="P1-I1">) +
        %(<instrument-name>Voice</instrument-name><instrument-sound>voice.male</instrument-sound></score-instrument></score-part></part-list>)
      expect(flow_with("", part_list: part_list).parts.first.instrument).to be_nil
    end
  end

  describe "the instrument" do
    def instrument_for(part_name: "Part", instrument_name: nil, sound: nil, virtual_name: nil, transpose: nil)
      score_instrument = [
        instrument_name && "<instrument-name>#{instrument_name}</instrument-name>",
        sound && "<instrument-sound>#{sound}</instrument-sound>",
        virtual_name && "<virtual-instrument><virtual-name>#{virtual_name}</virtual-name></virtual-instrument>"
      ].compact.join
      part_list = %(<part-list><score-part id="P1"><part-name>#{part_name}</part-name>) +
        %(<score-instrument id="P1-I1">#{score_instrument}</score-instrument></score-part></part-list>)
      xml = musicxml_measures(note_xml("C4", 4, "whole"))
      xml = xml.sub(%r{<part-list>.*</part-list>}m, part_list)
      xml = xml.sub("<divisions>", "#{transpose}<divisions>") if transpose
      HeadMusic::Notation::MusicXML.parse(xml).parts.first.instrument&.name_key
    end

    def transpose(chromatic, diatonic)
      "<transpose><diatonic>#{diatonic}</diatonic><chromatic>#{chromatic}</chromatic></transpose>"
    end

    it "reads the named instrument where the sound is its family's" do
      expect(instrument_for(instrument_name: "Irish tenor banjo", sound: "pluck.banjo.tenor")).to eq :irish_tenor_banjo
    end

    it "reads the sound where the name is another family's, as a part name labeling a player" do
      expect(instrument_for(part_name: "Soprano", sound: "wind.reed.saxophone.soprano")).to eq :soprano_saxophone
    end

    it "reads an instrument name with no sound" do
      expect(instrument_for(instrument_name: "clarinet in C")).to eq :clarinet_in_c
    end

    it "reads a part name where the instrument name names no instrument" do
      expect(instrument_for(part_name: "Clarinet in A", instrument_name: "SmartMusic SoftSynth", sound: "wind.reed.clarinet.bflat")).to eq :clarinet_in_a
    end

    it "reads a virtual instrument's name" do
      expect(instrument_for(virtual_name: "Oboe")).to eq :oboe
    end

    it "reads a sound with no name" do
      expect(instrument_for(sound: "brass.trumpet.bflat")).to eq :trumpet
    end

    it "reads a name in another language" do
      expect(instrument_for(instrument_name: "Klarinette")).to eq :clarinet
    end

    it "reads a name in another program's form" do
      expect(instrument_for(instrument_name: "C Clarinet", sound: "wind.reed.clarinet")).to eq :clarinet_in_c
    end

    it "gives a part no instrument where nothing resolves" do
      expect(instrument_for(part_name: "Melody", instrument_name: "Grand Synth", sound: "voice.male")).to be_nil
    end

    it "gives a part with no score instrument none, whatever its part name" do
      expect(flow_with("", names: ["Bass"]).parts.first.instrument).to be_nil
    end

    describe "picked by transposition, where only the sound names it" do
      it "reads the variant that transposes as the part does" do
        expect(instrument_for(sound: "wind.reed.clarinet", transpose: transpose(-3, -2))).to eq :clarinet_in_a
      end

      it "keeps the sound's instrument where no transposition is written" do
        expect(instrument_for(sound: "wind.reed.clarinet")).to eq :clarinet
      end

      it "keeps the sound's instrument where no variant transposes as the part does" do
        expect(instrument_for(sound: "wind.reed.clarinet", transpose: transpose(-5, -3))).to eq :clarinet
      end
    end
  end

  describe "reading back what the writer writes" do
    let(:project) { LayoutFixtures.clarinet_project }
    let(:original) { project.flows.first }
    let(:flow) { HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(original)) }

    it "keeps the instrument" do
      expect(flow.parts.first.instrument).to eq original.parts.first.instrument
    end

    it "keeps the player's name" do
      expect(flow.parts.first.player.name).to eq "Clarinet"
    end

    it "keeps a cited work and its composer" do
      work = HeadMusic::Content::Work.new(title: "Suite").with_credit(HeadMusic::Content::Person.new(full_name: "J. S. Bach"), :composer)
      cited = HeadMusic::Content::Flow.new(name: "Gigue", work: work).tap { |gigue| gigue.add_voice.place("1:1", :whole, "C4") }
      read = HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(cited))
      expect([read.name, read.work.title, read.composer]).to eq ["Gigue", "Suite", "J. S. Bach"]
    end
  end

  describe "reading back every instrument the writer writes" do
    def round_trip(instrument, transposed: false, locale: I18n.locale)
      flow = HeadMusic::Content::Flow.new(name: "Round Trip").tap do |written|
        written.add_part(instrument: instrument.name_key).add_voice.place("1:1", :whole, "C4")
      end
      xml = I18n.with_locale(locale) { HeadMusic::Notation::MusicXML.render(flow, transposed: transposed) }
      HeadMusic::Notation::MusicXML.parse(xml).parts.first.instrument
    end

    [false, true].each do |transposed|
      it "reads back every catalog instrument, with its transposition, #{transposed ? "transposed" : "at concert pitch"}" do
        lost = HeadMusic::Instruments::Instrument.all.reject do |instrument|
          read = round_trip(instrument, transposed: transposed)
          read == instrument && read.sounding_transposition == instrument.sounding_transposition
        end
        expect(lost.map(&:name_key)).to be_empty
      end
    end

    it "reads back an instrument named in another language" do
      instrument = HeadMusic::Instruments::Instrument.get("trumpet_in_e_flat")
      expect(round_trip(instrument, locale: :de)).to eq instrument
    end
  end
end
