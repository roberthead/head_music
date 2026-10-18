require "spec_helper"

describe HeadMusic::Notation::MEI::EventRecords do
  def parsed(*items)
    made = nil
    allow(described_class).to receive(:new).and_wrap_original do |original, *arguments|
      made = [original.call(*arguments), arguments[1]]
      made.first
    end
    HeadMusic::Notation::MEI.parse(mei_document(*items))
    made
  end

  let(:chord) { %(<chord dur="2">#{mei_note("C4", nil) + mei_note("E4", nil)}</chord>) }
  let(:bar) { mei_staff(1, %(<note pname="d" oct="4" dur="16" grace="unacc"/>) + chord + mei_note("G4", "2")) }
  let(:made) { parsed(bar) }
  let(:records) { made.first }
  let(:score) { made.last }

  def pending_of(kind)
    score.pending.find { |pending| pending.kind == kind && !pending.chord_member && !pending.grace }
  end

  it "makes each Pending's record once" do
    pending = score.pending.first
    expect(records[pending]).to equal records[pending]
  end

  it "records where an event sounds, in its bar" do
    record = records[pending_of(:note)]
    expect([record.voice_event.to_s, record.onset]).to eq ["half G4 at 1:3:000", Rational(1, 2)]
  end

  it "finds the notes and chords made that start at a position, not their tones or grace notes" do
    score.pending.each { |pending| records[pending] }
    expect(records.starting_at(records[pending_of(:chord)].voice_event.position).map(&:kind)).to eq [:chord]
  end
end
