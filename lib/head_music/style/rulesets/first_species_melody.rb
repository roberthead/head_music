# frozen_string_literal: true

# Module for rulesets
module HeadMusic::Style::Guides; end

# Rules for first species melodies
class HeadMusic::Style::Guides::FirstSpeciesMelody
  RULESET = [
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepOutOfUnison,
    HeadMusic::Style::Guidelines::StepUpToFinalNote,
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
