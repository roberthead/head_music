require "spec_helper"

describe MuseScoreFixtures do
  let(:directory) { described_class::DIRECTORY }
  let(:files) { Dir[File.join(directory, "**", "*.{xml,musicxml}")].sort }

  def root_name(path)
    REXML::Document.new(File.read(path)).root.name
  end

  it "commits only well-formed XML" do
    malformed = files.reject { |path| MuseScore.well_formed?(File.read(path)) }
    expect(malformed).to be_empty
  end

  it "commits a head_music render and its MuseScore conversion for every listed fixture" do
    expected = described_class.names.flat_map { |name| %w[head_music musescore4].map { |kind| described_class.path(name, kind) } }
    expect(Dir[File.join(directory, "*.{head_music,musescore4}.musicxml")].sort).to eq expected.sort
  end

  it "commits a score-timewise conversion for each listed timewise fixture" do
    roots = described_class::TIMEWISE.map { |name| root_name(described_class.path(name, "timewise")) }
    expect(roots).to all(eq "score-timewise")
  end

  it "commits the LilyPond MusicXML test suite files beside their license" do
    suite = File.join(directory, "lilypond_test_suite")
    expect(Dir[File.join(suite, "*.xml")].size).to eq 14
    expect(File.read(File.join(suite, "LICENSE"))).to include "MIT License"
  end
end
