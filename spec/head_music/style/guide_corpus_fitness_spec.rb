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
  # One example per corpus voice rather than one for the whole corpus, so a run
  # shows progress and a failure names the voice. The corpus is built at load
  # time to know the examples; the grading still happens inside each one.
  describe "grading the pinned corpus" do
    corpus = GuideGrading.corpus
    baseline = JSON.parse(
      File.read(File.expand_path("../../fixtures/style/corpus_fitness.json", __dir__)),
      symbolize_names: true
    )
    baseline_rows = baseline.group_by { |row| row[:corpus] }

    it "grades every pinned voice, in the pinned order" do
      expect(corpus.map(&:first)).to eq baseline_rows.keys
    end

    it "grades with every guide" do
      expect(baseline.map { |row| row[:guide] }.uniq).to match_array(described_class::ALL.map { |guide| described_class.key_for(guide) })
    end

    corpus.each do |label, voice|
      it "reproduces the snapshot for #{label}" do
        rows = GuideGrading.rows_for(label, voice)

        aggregate_failures do
          expect(rows.select { |row| row[:error] }).to be_empty
          expect(rows).to eq baseline_rows[label]
        end
      end
    end
  end
end
