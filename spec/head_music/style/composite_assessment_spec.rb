require "spec_helper"

# A guide is a duck type, so a member with a chosen gate and rubric is built
# rather than found. Two guide items -- one gate, one primary -- let an example
# name the gate factor and the rubric grade of a member independently, which no
# guide in the registry allows.
class StubMember
  def initialize(category, gate_fitness:, rubric_fitness:)
    @category = category
    @gate_fitness = gate_fitness
    @rubric_fitness = rubric_fitness
  end

  attr_reader :category

  def categories
    [category]
  end

  def composite?
    false
  end

  def key
    "stub_#{category}"
  end
  alias_method :name, :key
  alias_method :inspect, :key

  def assess(voice)
    HeadMusic::Style::GuideAssessment.new(self, voice)
  end

  # CompositeGuide resolves its members' items at construction, for display.
  # The grade comes from assess_items, so these need only be real GuideItems.
  def items_by_tier
    @items_by_tier ||= {
      gate: [HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::MinimumNotes, {minimum: 3})],
      primary: [HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::EndOnTonic, {})],
      secondary: []
    }
  end

  # Mirrors Guides::Assessment: a failed gate stops the assessment, so an
  # unassessable member reports its gate and nothing else.
  def assess_items(voice)
    gate = item_assessment(voice, tier: :gate, fitness: @gate_fitness)
    return [gate] unless gate.adherent?

    [gate, item_assessment(voice, tier: :primary, fitness: @rubric_fitness)]
  end

  private

  def item_assessment(voice, tier:, fitness:)
    HeadMusic::Style::GuideItemAssessment.new(
      voice: voice, tier: tier, fitness: fitness, marks: [],
      guide_item: HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::MinimumNotes, {minimum: 3})
    )
  end
end

describe HeadMusic::Style::CompositeAssessment do
  subject(:assessment) { guide.assess(voice) }

  let(:guide) { HeadMusic::Style::Guide.get!("first_species") }

  def composite_of(*members)
    HeadMusic::Style::Guides::CompositeGuide.new(members)
  end

  # A melody member gated out at a fraction, against an assessable harmony
  # member with a rubric below one. The only shape that tells the gate-factor
  # rule apart from an unconditional mean -- see the example that uses it.
  def fractionally_gated_composite
    composite_of(
      StubMember.new(:melody, gate_fitness: 0.25, rubric_fitness: 1.0),
      StubMember.new(:harmony, gate_fitness: 1.0, rubric_fitness: 0.5)
    )
  end

  describe "the assessment protocol" do
    context "with an adherent voice" do
      let(:voice) { fux_first_species_examples[0].counterpoint_voice }

      it_behaves_like "a style assessment", adherent: true
    end

    context "with a voice that grades below one" do
      let(:voice) { fux_first_species_examples[7].counterpoint_voice }

      it_behaves_like "a style assessment"
    end

    context "with a solo voice, which the harmony member gates out" do
      let(:voice) do
        flow = HeadMusic::Content::Flow.new(name: "Solo", key_signature: "D dorian")
        flow.add_voice(role: :counterpoint).tap do |part|
          %w[D4 F4 E4 D4].each_with_index { |pitch, bar| part.place("#{bar + 1}:1", :whole, pitch) }
        end
      end

      it_behaves_like "a style assessment", assessable: false
    end
  end

  # The shared group can only run what it already knows to ask for, so a method
  # added to one class and not the other is invisible to it. This is deliberately
  # unforgiving -- it forbids even a harmless override on one side -- because
  # that pressure is what keeps the two classes one protocol.
  it "declares the same public instance methods as a leaf assessment" do
    expect(described_class.public_instance_methods(false))
      .to match_array HeadMusic::Style::GuideAssessment.public_instance_methods(false)
  end

  describe "#fitness" do
    # Hand-computable: the melody member grades exactly 1.0, so the composite is
    # the square root of the harmony grade alone. It also differs from the
    # arithmetic mean in the third decimal, so one example pins both the value
    # and that it is not an average.
    context "with Fux chapter one figure 14" do
      let(:voice) { fux_first_species_examples[7].counterpoint_voice }

      it "is the geometric mean of its members' grades" do
        expect(assessment.fitness).to be_within(1e-9).of(Math.sqrt(0.869504831500))
      end

      it "is not the arithmetic mean" do
        expect(assessment.fitness).not_to be_within(1e-4).of(0.934752415750)
      end
    end

    context "with both members grading below one" do
      let(:voice) { fux_first_species_examples[1].counterpoint_voice }

      it "is the geometric mean of its members' grades" do
        melody, harmony = assessment.assessments.map(&:fitness)

        expect(assessment.fitness).to be_within(1e-12).of(Math.sqrt(melody * harmony))
      end
    end

    it "reads 0.707 rather than 0.75 for a perfect melody against a half-graded harmony" do
      guide = composite_of(
        StubMember.new(:melody, gate_fitness: 1.0, rubric_fitness: 1.0),
        StubMember.new(:harmony, gate_fitness: 1.0, rubric_fitness: 0.5)
      )

      expect(guide.assess(nil).fitness).to be_within(1e-12).of(Math.sqrt(0.5))
    end

    it "is zero when either member is zero" do
      guide = composite_of(
        StubMember.new(:melody, gate_fitness: 1.0, rubric_fitness: 1.0),
        StubMember.new(:harmony, gate_fitness: 1.0, rubric_fitness: 0.0)
      )

      expect(guide.assess(nil).fitness).to eq 0.0
    end

    it "is exactly one when both members are exactly one" do
      guide = composite_of(
        StubMember.new(:melody, gate_fitness: 1.0, rubric_fitness: 1.0),
        StubMember.new(:harmony, gate_fitness: 1.0, rubric_fitness: 1.0)
      )

      expect(guide.assess(nil).fitness).to eq 1.0
    end
  end

  describe "an unassessable composite" do
    let(:voice) do
      flow = HeadMusic::Content::Flow.new(name: "Solo", key_signature: "D dorian")
      flow.add_voice(role: :counterpoint).tap do |part|
        %w[D4 F4 E4 G4 F4 A4 G4 F4].each_with_index { |pitch, bar| part.place("#{bar + 1}:1", :whole, pitch) }
      end
    end

    let(:lower_voice) do
      flow = HeadMusic::Content::Flow.new(name: "Solo", key_signature: "D dorian")
      flow.add_voice(role: :counterpoint).tap do |part|
        %w[D4 E4 E4 E4 E4 E4 E4 D4].each_with_index { |pitch, bar| part.place("#{bar + 1}:1", :whole, pitch) }
      end
    end

    it "is not assessable, because the harmony member has no companion voice" do
      expect(assessment).not_to be_assessable
      expect(assessment.assessments.map(&:assessable?)).to eq [true, false]
    end

    it "grades zero" do
      expect(assessment.fitness).to eq 0.0
    end

    # The premise the example above rests on. Without it, "the grade did not
    # move" would be proving nothing: the two melodies have to actually differ
    # against the melody member for their shared composite grade to mean
    # anything.
    it "grades zero whatever the melody does, and the two melodies do differ" do
      melody_member = HeadMusic::Style::Guides::FirstSpeciesMelody
      grades = [voice, lower_voice].map { |part| melody_member.assess(part) }

      expect(grades.map(&:assessable?)).to eq [true, true]
      expect(grades.first.fitness).to be > grades.last.fitness
      expect(guide.assess(lower_voice).fitness).to eq 0.0
    end

    # The only example in the suite that fails if CompositeAssessment#fitness
    # stops branching on assessable?. No voice in the registry can tell the two
    # rules apart: the members share MinimumNotes.with(3) and fail it
    # identically, and SetAgainstAnotherVoice -- the only gate that
    # distinguishes them -- scores exactly 0 or 1, so a solo voice reads 0.0
    # either way. Do not delete this as artificial.
    it "grades on gate factors alone rather than letting an assessable member's rubric in" do
      graded = fractionally_gated_composite.assess(nil)

      expect(graded.fitness).to be_within(1e-12).of(0.5)
      expect(graded.fitness).not_to be_within(1e-3).of(Math.sqrt(0.25 * 0.5))
    end
  end

  describe "#fitness_by_category" do
    let(:voice) { fux_first_species_examples[7].counterpoint_voice }

    it "reports a grade for each member's category" do
      expect(assessment.fitness_by_category.keys).to eq %i[melody harmony]
    end

    it "reports each member's own grade" do
      expect(assessment.fitness_by_category.values)
        .to eq assessment.assessments.map(&:fitness)
    end

    it "follows fitness onto gate factors when the composite is unassessable" do
      by_category = fractionally_gated_composite.assess(nil).fitness_by_category

      expect(by_category).to eq({melody: 0.25, harmony: 1.0})
    end
  end

  describe "#messages" do
    let(:voice) { fux_first_species_examples.first.counterpoint_voice }

    it "reports its members' messages in member order" do
      melody, harmony = assessment.assessments

      expect(assessment.messages).to eq melody.messages + harmony.messages
    end
  end

  describe "#assessments" do
    let(:voice) { fux_first_species_examples[7].counterpoint_voice }

    it "holds one assessment per member, in member order" do
      expect(assessment.assessments.map(&:guide)).to eq guide.guides
    end

    it "memoizes, so a consumer reading it twice sees one analysis" do
      first_read = assessment.assessments

      expect(assessment.assessments).to be first_read
    end
  end

  describe "construction" do
    let(:voice) { HeadMusic::Content::Voice.new }

    it "refuses a leaf guide, which grades through GuideAssessment instead" do
      expect { described_class.new(HeadMusic::Style::Guides::FirstSpeciesMelody, voice) }
        .to raise_error(ArgumentError, /must be a composite/)
    end

    it "refuses a guide that is not a guide at all" do
      expect { described_class.new(nil, voice) }.to raise_error(ArgumentError, /must be a composite/)
    end
  end
end
