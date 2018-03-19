# frozen_string_literal: true

# Module for rulesets
module HeadMusic::Style::Guides; end

# Modern rules for the cantus firmus
class HeadMusic::Style::Guides::ModernCantusFirmus
  RULESET = [
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::AtLeastEightNotes,
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange,
    HeadMusic::Style::Guidelines::SingleLargeLeaps,
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepToFinalNote,
    HeadMusic::Style::Guidelines::UpToFourteenNotes,
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
