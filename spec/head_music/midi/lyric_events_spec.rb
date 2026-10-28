require "spec_helper"

describe HeadMusic::MIDI::LyricEvents do
  subject(:lyric_events) { described_class.new(flow) }

  let(:flow) { HeadMusic::Content::Flow.new(name: "Lyrics") }
  let(:part) { flow.add_part }
  let(:upper) { part.add_voice }
  let(:lower) { part.add_voice }

  it "sings the syllable" do
    note = upper.place("1:1", :whole, "C5").sing("Glo")
    expect(lyric_events.text_for(note, 1)).to eq "Glo"
  end

  it "appends a hyphen when the word continues" do
    note = upper.place("1:1", :whole, "C5").sing("Glo", hyphen_after: true)
    expect(lyric_events.text_for(note, 1)).to eq "Glo-"
  end

  it "sings nothing for a note with no syllable" do
    note = upper.place("1:1", :whole, "C5")
    expect(lyric_events.text_for(note, 1)).to be_nil
  end

  it "sings nothing for a held note of a melisma" do
    upper.place("1:1", :half, "C5").sing("Glo")
    held = upper.place("1:3", :half, "D5").extend_syllable
    expect(lyric_events.text_for(held, 1)).to be_nil
  end

  describe "verses by pass" do
    let!(:first) { upper.place("1:1", :half, "C5").sing("one").sing("two", verse: 2) }
    let!(:second) { upper.place("1:3", :half, "D5").sing("three") }

    it "sings verse n on pass n" do
      expect(lyric_events.text_for(first, 2)).to eq "two"
    end

    it "sings verse 1 on a pass with no verse of its own" do
      expect(lyric_events.text_for(first, 3)).to eq "one"
    end

    it "sings nothing on a pass whose verse the flow has but the note lacks" do
      expect(lyric_events.text_for(second, 2)).to be_nil
    end
  end

  context "with two voices of a part singing at one onset" do
    let!(:high) { upper.place("1:1", :whole, "C5").sing("Glo") }
    let!(:low) { lower.place("1:1", :whole, "C4").sing("Ky") }

    it "sings the first voice's syllable" do
      expect(lyric_events.text_for(high, 1)).to eq "Glo"
    end

    it "sings nothing for the later voice" do
      expect(lyric_events.text_for(low, 1)).to be_nil
    end

    it "lets the later voice sing where the first voice has no syllable for the verse" do
      low.sing("e", verse: 2)
      expect(lyric_events.text_for(low, 2)).to eq "e"
    end
  end

  it "lets voices of different parts sing at one onset" do
    high = upper.place("1:1", :whole, "C5").sing("Glo")
    low = flow.add_part.add_voice.place("1:1", :whole, "C4").sing("Ky")
    expect([lyric_events.text_for(high, 1), lyric_events.text_for(low, 1)]).to eq %w[Glo Ky]
  end
end
