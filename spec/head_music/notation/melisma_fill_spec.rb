require "spec_helper"

describe HeadMusic::Notation::MelismaFill do
  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
  let(:voice) { flow.add_voice }

  def held(verse = 1)
    voice.voice_events.map { |voice_event| voice_event.extends_syllable?(verse) }
  end

  # Quarter notes from beat 1, each sung, unsung (nil), or a rest.
  def quarters(*lyrics)
    lyrics.each.with_index(1).map do |lyric, beat|
      voice_event = voice.place("1:#{beat}", :quarter, (lyric == :rest) ? nil : "C4")
      lyric.is_a?(String) ? voice_event.sing(lyric) : voice_event
    end
  end

  it "holds the syllable up to the next sung note" do
    described_class.fill(quarters("Lord", nil, nil, "praise").first, 1)
    expect(held).to eq [false, true, true, false]
  end

  it "stops at a rest" do
    described_class.fill(quarters("Lord", nil, :rest, nil).first, 1)
    expect(held).to eq [false, true, false, false]
  end

  it "stops at a gap" do
    lord = voice.place("1:1", :quarter, "C4").sing("Lord")
    voice.place("1:3", :quarter, "E4")
    described_class.fill(lord, 1)
    expect(held).to eq [false, false]
  end

  it "fills one verse, leaving another sung there alone" do
    lord = voice.place("1:1", :quarter, "C4").sing("Lord").sing("O", verse: 2)
    voice.place("1:2", :quarter, "D4").sing("sing", verse: 2)
    described_class.fill(lord, 1)
    expect([held(1), held(2)]).to eq [[false, true], [false, false]]
  end

  it "holds on through a note already holding the verse" do
    lord = voice.place("1:1", :quarter, "C4").sing("Lord")
    voice.place("1:2", :quarter, "D4").extend_syllable
    voice.place("1:3", :quarter, "E4")
    described_class.fill(lord, 1)
    expect(held).to eq [false, true, true]
  end

  it "holds a hyphenated syllable up to its next one" do
    glo = voice.place("1:1", :quarter, "C4").sing("Glo", hyphen_after: true)
    voice.place("1:2", :half, "D4")
    voice.place("1:4", :quarter, "E4").sing("ri", hyphen_after: true)
    described_class.fill(glo, 1)
    expect(held).to eq [false, true, false]
  end
end
