require "spec_helper"

# The Bach chorales through kern import, MIDI export with their repeats
# taken out, and MIDI import, trusting the file's signatures and inferring
# the key. Run only when KERN_CORPUS names a local clone (see KernCorpus).
# The figures are recorded in user-stories/current/midi-import.md, beside
# Key and Spelling Inference's 99.945% with the key given and 99.947%
# inferred.
describe "HeadMusic::MIDI" do
  # Chorales that MIDI import refuses, by name; none is expected.
  refusals = {}.freeze

  before { skip "set KERN_CORPUS to a local clone of the Bach chorales" unless KernCorpus.directory }

  # {[part, onset, key number] => written pitches}
  def written_pitches(flow)
    MIDIRoundTrip.spellings(flow)
  end

  # Each imported note's pitch against the written ones at its part, onset,
  # and key, with the rule that spelled it. A respelling of the imported
  # flow under the same key reproduces the import's speller, rules and all.
  def misses(written, flow, key)
    respelling = HeadMusic::Analysis::PitchSpeller::Respelling.new(flow, key: key)
    expected = written_pitches(written)
    hash = flow.to_h
    respelling.addresses.zip(respelling.spelled_notes, HeadMusic::Analysis::NoteInput.for(flow).notes).filter_map do |address, spelled_note, note|
      pitch = hash.dig(*address)
      next [:unreproduced, spelled_note.rule] unless spelled_note.pitch.to_s == pitch

      [:note, spelled_note.rule] unless expected.fetch([address[1], note.onset, note.number], []).include?(pitch)
    end
  end

  def tally(paths)
    figures = Hash.new(0)
    misses_by_rule = {given: Hash.new(0), inferred: Hash.new(0)}
    refused = {}
    paths.each do |path|
      written = MIDIRoundTrip.without_navigation(HeadMusic::Notation::Kern.parse(File.read(path)))
      bytes = HeadMusic::MIDI.render(written)
      expected_notes = MIDIRoundTrip.notes(written)
      figures[:count] += HeadMusic::Analysis::NoteInput.for(written).notes.length
      {given: nil, inferred: :infer}.each do |measure, key|
        flow = HeadMusic::MIDI.parse(bytes, key: key)
        figures[[measure, :structural]] += 1 if MIDIRoundTrip.notes(flow) == expected_notes
        misses(written, flow, key).each { |miss| misses_by_rule[measure][miss] += 1 }
        if measure == :given
          figures[:music] += 1 if MIDIRoundTrip.music(flow) == MIDIRoundTrip.music(written)
          figures[:events] += 1 if MIDIRoundTrip.events(HeadMusic::MIDI.render(flow)) == MIDIRoundTrip.events(bytes)
        elsif flow.key_signature == written.key_signature
          figures[:key_agrees] += 1
        end
      rescue HeadMusic::MIDI::ParseError => error
        refused[[File.basename(path), measure]] = error.class
      end
      figures[:chorales] += 1
    end
    [figures, misses_by_rule, refused]
  end

  def accuracy(figures, misses_by_rule, measure)
    missed = misses_by_rule[measure].sum { |(kind, _), count| (kind == :note) ? count : 0 }
    Rational(figures[:count] - missed, figures[:count])
  end

  # The misses of each rule past its ceiling; a rule with no ceiling has none to spare.
  def beyond(misses, ceilings)
    misses.select { |rule, count| count > ceilings.fetch(rule, 0) }
  end

  it "reads every chorale's notes back, and spells them at least as well as measured" do # rubocop:disable RSpec/ExampleLength
    figures, misses_by_rule, refused = tally(KernCorpus.readable_paths)
    chorales = figures[:chorales]

    aggregate_failures do
      expect(refused).to eq refusals
      expect(figures.values_at(:chorales, :count)).to eq [366, 83_196]
      expect(figures.values_at([:given, :structural], [:inferred, :structural], :music, :events)).to eq [chorales] * 4

      expect(accuracy(figures, misses_by_rule, :given)).to be >= Rational(83_196 - 51, 83_196)
      expect(accuracy(figures, misses_by_rule, :inferred)).to be >= Rational(83_196 - 44, 83_196)
      expect(beyond(misses_by_rule[:given], {[:note, :direction] => 41, [:note, :center] => 5, [:note, :raised] => 4, [:note, :sonority] => 1})).to be_empty
      expect(beyond(misses_by_rule[:inferred], {[:note, :direction] => 34, [:note, :center] => 5, [:note, :raised] => 4, [:note, :sonority] => 1})).to be_empty

      expect(figures[:key_agrees]).to be >= 315
    end
  end
end
