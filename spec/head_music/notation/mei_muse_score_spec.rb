require "spec_helper"

# MuseScore 4 reads each golden MEI document and writes it back as MusicXML,
# whose pitches and written durations, measure by measure, must be the flow's.
# Ties and rests are left out, since MuseScore drops @tie, and so are the
# measure numbers, since it numbers an upbeat measure 1. A measure's notes are
# pooled across its parts, since MuseScore makes a part of each staff in a
# braced group with no <label>.
#
# Three rewrites get a document past MuseScore's MEI import:
# - meiversion="5.1+basic", the only version it reads; it hangs on any other;
# - a <layer> holding <mRest/> in a bare <staff/>, which it rejects;
# - no <label> inside <layerDef>, on which it crashes.
describe HeadMusic::Notation::MEI do
  converting = MuseScore.available? && (!ENV["MSCORE"].to_s.empty? || ENV["MUSESCORE_FIXTURES"] == "1")

  misreads = {
    "clarinet_changes_transposed" => "MuseScore ignores @trans.diat and @trans.semi on a <staffDef> after the " \
      "opening, so it hears the A clarinet and the flute through the B-flat clarinet's transposition"
  }

  before { skip "set MSCORE, or MUSESCORE_FIXTURES=1 with MuseScore 4 installed, to convert the goldens through it" unless converting }

  def for_muse_score(mei)
    mei.sub('meiversion="5.1"', 'meiversion="5.1+basic"')
      .gsub(%r{<staff ([^>]*)/>}, '<staff \1><layer n="1"><mRest/></layer></staff>')
      .gsub(%r{<layerDef ([^>]*)>\s*<label[^>]*>[^<]*</label>\s*</layerDef>}, '<layerDef \1/>')
  end

  def convert(mei)
    Dir.mktmpdir("mei") do |directory|
      source = File.join(directory, "source.mei")
      File.write(source, for_muse_score(mei))
      HeadMusic::Notation::MusicXML.parse(MuseScore.convert_file(source, File.join(directory, "converted.musicxml"), timeout: 60))
    end
  end

  # For each measure in turn, every note and grace note of the score as its
  # pitches and its written length and ratio.
  def measures(flow)
    links = flow.voices.flat_map do |voice|
      HeadMusic::Notation::WrittenLinks.for(HeadMusic::Notation::BarSplitter.segments(voice.note_events))
    end
    links.group_by(&:bar_number).sort.map do |_, bar_links|
      bar_links.flat_map { |link| written_notes(link) }.sort
    end
  end

  def written_notes(link)
    voice_event = link.segment.voice_event
    graces = (link.segment.elapsed.zero? && link.index.zero?) ? voice_event.grace_notes : []
    graces.map { |grace| ["grace", grace.pitches.map(&:to_s).sort, grace.rhythmic_value.written_fraction] } +
      [["note", voice_event.pitches.map(&:to_s).sort, link.written_fraction, link.ratio&.to_a]]
  end

  it "lists only misreads of goldens that exist" do
    expect(misreads.keys - MEIFixtures.names).to eq []
  end

  MEIFixtures.names.each do |name|
    it "reads the #{name} golden back as its pitches and durations, measure by measure" do
      pending(misreads[name]) if misreads.key?(name)
      converted = convert(File.read(MEIFixtures.path(name)))
      expect(measures(converted)).to eq measures(MEIFixtures.source(name))
    end
  end
end
