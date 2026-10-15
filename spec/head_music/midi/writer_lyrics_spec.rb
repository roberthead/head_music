require "spec_helper"

describe HeadMusic::MIDI::Writer do
  def lyrics(flow)
    render_midi(flow).tracks[1].lyrics.map { |lyric| [lyric.tick, lyric.text] }
  end

  context "with two verses over a repeat, after a bar-0 pickup" do
    let(:flow) do
      MuseScoreFixtures.two_verses.tap { |flow| flow.bar(flow.latest_bar_number).ends_repeat_after_num_plays = 2 }
    end

    it "sings the first verse from the pickup's first note" do
      expect(lyrics(flow).first(4)).to eq [[0, "A-"], [480, "ma-"], [1440, "zing"], [1920, "grace"]]
    end

    it "sings the second verse on the second pass, from the pickup's note" do
      expect(lyrics(flow).drop(14).first(3)).to eq [[10560, "'Twas"], [11040, "grace"], [12000, "that"]]
    end

    it "ends each pass with its own verse" do
      expect(lyrics(flow).values_at(13, -2, -1)).to eq [[9120, "me."], [19200, "re-"], [19680, "lieved."]]
    end

    it "sings once per sung note on each pass" do
      expect(lyrics(flow).length).to eq 28
    end
  end

  describe "non-ASCII text" do
    let(:flow) { HeadMusic::Content::Flow.new(name: "Lyrics") }

    before do
      voice = flow.add_voice
      voice.place("1:1", :half, "C5").sing("Glò", hyphen_after: true)
      voice.place("1:3", :half, "D5").sing("Слава")
    end

    it "decodes Latin accented and Cyrillic syllables exactly" do
      expect(lyrics(flow)).to eq [[0, "Glò-"], [960, "Слава"]]
    end

    it "writes them as UTF-8 bytes" do
      expect(flow.to_midi).to include("Слава".b, "Glò-".b)
    end
  end

  context "with two voices of a part singing at one onset" do
    let(:flow) { HeadMusic::Content::Flow.new(name: "Lyrics") }

    it "writes only the first voice's syllable" do
      part = flow.add_part
      part.add_voice.place("1:1", :whole, "E4").sing("Ky")
      part.add_voice.place("1:1", :whole, "C4").sing("Glo")
      expect(lyrics(flow)).to eq [[0, "Ky"]]
    end
  end
end
