require "spec_helper"

# An original four-part setting, written for these specs, with what a Bach
# chorale in the KernScores corpus carries: a pickup and a short final bar,
# ties across barlines, a repeat in the middle of a bar, SATB names and
# codes, a tenor clef, a lyric spine, and the reference records of a work.
describe HeadMusic::Notation::Kern do
  subject(:flow) { described_class.parse(File.read(File.expand_path("../../fixtures/notation/kern/satb_chorale.krn", __dir__))) }

  let(:soprano) { flow.parts.first.voices.first }

  it "reads four parts, Soprano to Bass" do
    expect(flow.parts.map { |part| [part.player.name, part.instrument.name_key] })
      .to eq [%w[Soprano soprano_voice], %w[Alto alto_voice], %w[Tenor tenor_voice], %w[Bass bass_voice]].map { |name, key| [name, key.to_sym] }
  end

  it "reads the tenor's octave-treble clef" do
    expect(flow.parts[2].staff_system.first_staff.clef.name_key).to eq "vocal_tenor_clef"
  end

  it "reads the pickup as bar 0, padded before its first note" do
    expect(soprano.placements.first(2).map(&:to_s)).to eq ["half rest at 0:1:000", "quarter G4 at 0:3:000"]
  end

  it "reads the key, its reading, the meter, and the tempo" do
    expect([flow.key_signature.name, flow.meter.to_s, flow.tempo.beats_per_minute]).to eq ["G major", "3/4", 100]
  end

  it "fuses a tie across a barline into one placement" do
    expect(flow.parts[1].voices.first.placements.map(&:to_s)).to include "quarter tied to eighth F♯4 at 1:3:000"
  end

  it "marks the repeat on the bar that holds it" do
    expect(flow.to_h["bars"]).to eq [{"number" => 2, "ends_repeat_after_num_plays" => 2}]
  end

  it "sings the text spine on the soprano" do
    words = soprano.placements.filter_map { |placement| placement.syllable&.then { |syllable| "#{syllable.text}#{"-" if syllable.hyphen_after?}" } }
    expect(words.join(" ")).to eq "Wake the morn- ing light now the day is be- gun"
  end

  it "cites the work" do
    expect([flow.name, flow.work.title, flow.work.catalog_number, flow.work.year]).to eq ["Wake the Morning", "Wake the Morning", "HM 1", 1950]
  end

  it "credits the composer by full name, sort name, and lifespan" do
    expect(flow.work.credits.for(:composer).map { |credit| credit.person.to_h })
      .to eq [{"full_name" => "Jane Doe", "sort_name" => "Doe, Jane", "birth_year" => 1901, "death_year" => 1977}]
  end

  it "reads back to itself from what it writes" do
    expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
  end

  it "renders to MusicXML and LilyPond" do
    expect([flow.to_musicxml, flow.to_lilypond]).to all(be_a(String))
  end
end
