# The protocol GuideAssessment and CompositeAssessment both answer.
#
# Grading through two classes buys the right arithmetic at each level -- rules
# inside a rubric trade off by weight, while a melody grade and a harmony grade
# must both hold -- and costs the guarantee a single class would have given for
# free: that the two stay the same shape. This is what buys it back.
#
# Including specs define `guide` and `voice`, and declare which kind of voice
# they are supplying. Declaring it rather than branching on it keeps every
# example unconditional: the group checks the classification too, so a voice
# that stops being unassessable fails here instead of quietly skipping the rule
# that only unassessable voices exercise.
#
# The assertions that earn their place are relations BETWEEN methods. A method
# answering the wrong type fails loudly on its own; two methods quietly
# disagreeing about the same voice is the failure that ships.
RSpec.shared_examples "a style assessment" do |assessable: true, adherent: false|
  subject(:assessment) { guide.assess(voice) }

  it "is about the guide and voice it was asked for" do
    expect(assessment.guide).to be guide
    expect(assessment.voice).to be voice
  end

  # The composite pattern itself: whatever the assessment reports, its members
  # reported first, in order. eq rather than equal? -- a leaf allocates a fresh
  # [self] on every call.
  it "reports exactly what its members report" do
    expect(assessment.assessments.flat_map(&:guide_item_assessments)).to eq assessment.guide_item_assessments
    expect(assessment.assessments.flat_map(&:messages)).to eq assessment.messages
  end

  it "grades every member against the voice it was given" do
    expect(assessment.assessments).not_to be_empty
    expect(assessment.assessments.map(&:voice).uniq).to eq [voice]
  end

  it "is assessable exactly when every gate it reports is adherent" do
    gates = assessment.guide_item_assessments.select(&:gate?)

    expect(assessment.assessable?).to be assessable
    expect(assessment.assessable?).to eq gates.all?(&:adherent?)
    expect(assessment.adherent?).to be adherent
  end

  # GuideAssessment's own sentence -- "a voice failing a precondition has not
  # earned a bad grade on the rest, so fitness is the gates alone" -- asserted
  # on both, so the two cannot come to disagree about what a gate means.
  unless assessable
    it "grades on gates alone rather than on a rubric it never earned" do
      expect(assessment.fitness).to eq assessment.gate_factor
    end
  end

  it "grades in the unit interval" do
    expect(assessment.fitness).to be_a(Float).and be_between(0.0, 1.0)
    expect(assessment.gate_factor).to be_a(Float).and be_between(0.0, 1.0)
  end

  # One direction only, and exactly 1.0 rather than nearly: a composite reaches
  # it through a square root, so this is also what pins the geometric mean
  # against a log-sum form that would land a hair below.
  if adherent
    it "grades exactly 1.0 and says nothing" do
      expect(assessment.fitness).to eq 1.0
      expect(assessment.messages).to be_empty
    end
  end

  it "splits its grade by category without losing a member" do
    by_category = assessment.fitness_by_category

    categories = assessment.guide.categories

    expect(by_category).to be_a(Hash)
    expect(by_category.keys).to match_array(categories.empty? ? [nil] : categories)
  end
end
