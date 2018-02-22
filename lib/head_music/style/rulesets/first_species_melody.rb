# frozen_string_literal: true

# Module for rulesets
module HeadMusic::Style::Rulesets; end

# Rules for first species melodies
class HeadMusic::Style::Rulesets::FirstSpeciesMelody
  RULESET = [
    HeadMusic::Style::Annotations::ConsonantClimax,
    HeadMusic::Style::Annotations::Diatonic,
    HeadMusic::Style::Annotations::EndOnTonic,
    HeadMusic::Style::Annotations::FrequentDirectionChanges,
    HeadMusic::Style::Annotations::LimitOctaveLeaps,
    HeadMusic::Style::Annotations::MostlyConjunct,
    HeadMusic::Style::Annotations::NoRests,
    HeadMusic::Style::Annotations::NotesSameLength,
    HeadMusic::Style::Annotations::PrepareOctaveLeaps,
    HeadMusic::Style::Annotations::SingableIntervals,
    HeadMusic::Style::Annotations::SingableRange,
    HeadMusic::Style::Annotations::StartOnPerfectConsonance,
    HeadMusic::Style::Annotations::StepOutOfUnison,
    HeadMusic::Style::Annotations::StepUpToFinalNote,
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
