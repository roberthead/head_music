require "spec_helper"
require "json"

# Every guide's assessment of every corpus voice, pinned before the content
# containers were restructured.
#
# The guide specs assert marks_count on hand-built material, which is a
# different claim: they pin what a guideline notices, not what a student's grade
# comes out as end to end. This pins the grade -- so a container refactor that
# silently changes which voice a guide can see, or whether it can see one at
# all, fails here instead of passing everything and quietly regrading the
# corpus.
#
# Regenerate with `rake style:snapshot_corpus_fitness` -- but only after
# deciding a grade should change, which is a decision, not a refactor.
describe HeadMusic::Style::Guide do
  # Grading the whole corpus takes about ten seconds, so the three claims share
  # one pass rather than each paying for their own.
  describe "grading the pinned corpus" do
    subject(:rows) { GuideGrading.rows }

    let(:baseline) do
      JSON.parse(
        File.read(File.expand_path("../../fixtures/style/corpus_fitness.json", __dir__)),
        symbolize_names: true
      )
    end

    let(:guide_keys) { described_class::ALL.map { |guide| described_class.key_for(guide) } }

    it "reproduces the snapshot taken before the refactor" do
      aggregate_failures do
        expect(rows.select { |row| row[:error] }).to be_empty
        expect(rows.map { |row| row[:guide] }.uniq).to match_array guide_keys
        expect(rows).to eq baseline
      end
    end
  end
end
