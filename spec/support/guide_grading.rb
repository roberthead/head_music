# Grades a fixed corpus of voices against every registered guide.
#
# The corpus deliberately mixes degenerate material (empty voices, one note, a
# repeated pitch) with the published examples, because a container refactor
# breaks the degenerate cases first: those are the ones where a guide reaches
# through a voice for something that may not be there.
#
# Used by the pinned snapshot in spec/fixtures/style/corpus_fitness.json and by
# bin/guide_grade_corpus.rb, so one definition of the corpus serves both.
module GuideGrading
  LADDER = %w[D4 F4 E4 G4 F4 A4 G4 F4].freeze
  REPEATED = Array.new(8, "E4").freeze
  CANTUS = %w[D4 F4 E4 D4 G4 F4 E4 D4].freeze

  PUBLISHED_SOURCES = %w[
    fux_cantus_firmus_examples clendinning_cantus_firmus_examples
    schoenberg_cantus_firmus_examples davis_and_lybbert_cantus_firmus_examples
    fux_cantus_firmus_examples_with_errors fux_first_species_examples
    clendinning_first_species_examples davis_and_lybbert_first_species_examples
    doubled_octave_examples
  ].freeze

  module_function

  def rows
    corpus.flat_map do |label, voice|
      HeadMusic::Style::Guide::ALL.map do |guide|
        {
          corpus: label,
          notes: voice.notes.length,
          guide: HeadMusic::Style::Guide.key_for(guide)
        }.merge(grade(guide, voice))
      end
    end
  end

  def corpus
    entries = []
    (0..8).each { |n| entries << ["solo-ascending-#{n}", solo(LADDER.first(n))] }
    (0..8).each { |n| entries << ["solo-repeated-#{n}", solo(REPEATED.first(n))] }
    [0, 1, 2, 4, 8].each { |n| entries << ["against-empty-#{n}", accompanied(LADDER.first(n), [])] }
    [0, 1, 2, 4, 8].each { |n| entries << ["against-cantus-#{n}", accompanied(LADDER.first(n), CANTUS)] }

    PUBLISHED_SOURCES.each do |source|
      Array(send(source)).each_with_index do |context, index|
        context.flow.voices.each_with_index do |voice, position|
          entries << ["#{source}-#{index}-v#{position}", voice]
        end
      end
    end
    entries
  end

  # Through the guide, not GuideAssessment.new: a composite guide grades its
  # members separately and refuses that constructor.
  def grade(guide, voice)
    assessment = guide.assess(voice)
    items = assessment.guide_item_assessments
    {
      fitness: assessment.fitness.round(12),
      adherent: assessment.adherent?,
      message_count: assessment.messages.length,
      item_count: items.length,
      assessable: assessment.assessable?,
      failed_gates: items.select { |item| item.gate? && !item.adherent? }.map { |item| item.guideline.name.split("::").last }.sort
    }
  rescue => error
    {fitness: nil, adherent: nil, message_count: nil, item_count: nil, assessable: nil,
     failed_gates: [], error: error.class.name}
  end

  def flow(key: "D dorian")
    HeadMusic::Content::Flow.new(name: "corpus", key_signature: key)
  end

  def place(voice, pitches)
    pitches.each_with_index { |pitch, bar| voice.place("#{bar + 1}:1", :whole, pitch) }
    voice
  end

  # A voice alone in its flow: no companion, so the harmony guides have
  # nothing to be set against.
  def solo(pitches)
    place(flow.add_voice(role: :counterpoint), pitches)
  end

  # A counterpoint voice with a companion, which may itself be empty.
  def accompanied(pitches, companion_pitches)
    comp = flow
    place(comp.add_voice(role: "Cantus Firmus"), companion_pitches)
    place(comp.add_voice(role: :counterpoint), pitches)
  end
end
