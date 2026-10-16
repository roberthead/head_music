require "spec_helper"

# The Bach chorales, stripped to key numbers: respelled by the key signature
# and designation in force and under inferred keys, and the inferred key of
# each against its designation, a mode's being its parallel key. Run only when
# KERN_CORPUS names a local clone (see KernCorpus). The figures are recorded in
# user-stories/current/key-and-spelling-inference.md.
describe "HeadMusic::Analysis::PitchSpeller" do
  before { skip "set KERN_CORPUS to a local clone of the Bach chorales" unless KernCorpus.directory }

  def designation(flow)
    tonal_context = flow.timeline.tonal_context_at(flow.earliest_bar_number)
    tonal_context.is_a?(HeadMusic::Rudiment::Mode) ? [:modal, tonal_context.parallel] : [:major_or_minor, tonal_context]
  end

  def tally(flows)
    figures = Hash.new(0)
    misses_by_rule = {given: Hash.new(0), inferred: Hash.new(0)}
    flows.each do |flow|
      {given: nil, inferred: :infer}.each do |measure, key|
        evaluation = SpellingEvaluation.misses(flow, key: key)
        figures[[measure, :count]] += evaluation[:count]
        figures[[measure, :grace_count]] += evaluation[:grace_count]
        evaluation[:misses].each { |miss| misses_by_rule[measure][[miss.grace? ? :grace : :note, miss.rule]] += 1 }
      end
      kind, key = designation(flow)
      finder = HeadMusic::Analysis::KeyFinder.new(flow)
      figures[[kind, :chorales]] += 1
      figures[[kind, :whole_piece]] += 1 if finder.key.name == key.name
      figures[[kind, :first_region]] += 1 if finder.regions.first.key.name == key.name
    end
    [figures, misses_by_rule]
  end

  def accuracy(figures, misses_by_rule, measure)
    missed = misses_by_rule[measure].sum { |(kind, _), count| (kind == :note) ? count : 0 }
    Rational(figures[[measure, :count]] - missed, figures[[measure, :count]])
  end

  # The misses of each rule past its ceiling; a rule with no ceiling has none to spare.
  def beyond(misses, ceilings)
    misses.select { |rule, count| count > ceilings.fetch(rule, 0) }
  end

  it "spells and finds keys at least as well as measured" do # rubocop:disable RSpec/ExampleLength
    figures, misses_by_rule = tally(KernCorpus.readable_paths.map { |path| HeadMusic::Notation::Kern.parse(File.read(path)) })

    aggregate_failures do
      expect(figures.values_at([:given, :count], [:inferred, :count], [:given, :grace_count])).to eq [83_196, 83_196, 0]
      expect(figures.values_at([:major_or_minor, :chorales], [:modal, :chorales])).to eq [319, 47]

      expect(accuracy(figures, misses_by_rule, :given)).to be >= Rational(83_196 - 46, 83_196)
      expect(accuracy(figures, misses_by_rule, :inferred)).to be >= Rational(83_196 - 44, 83_196)
      expect(beyond(misses_by_rule[:given], {[:note, :direction] => 34, [:note, :raised] => 7, [:note, :center] => 4, [:note, :sonority] => 1})).to be_empty
      expect(beyond(misses_by_rule[:inferred], {[:note, :direction] => 34, [:note, :center] => 5, [:note, :raised] => 4, [:note, :sonority] => 1})).to be_empty

      expect(figures[[:major_or_minor, :whole_piece]]).to be >= 295
      expect(figures[[:modal, :whole_piece]]).to be >= 37
      expect(figures[[:major_or_minor, :first_region]]).to be >= 300
      expect(figures[[:modal, :first_region]]).to be >= 39
    end
  end
end
