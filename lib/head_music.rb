module HeadMusic
  GOLDEN_RATIO = (1 + 5**0.5) / 2.0
  GOLDEN_RATIO_INVERSE = 1 / GOLDEN_RATIO
  PENALTY_FACTOR = GOLDEN_RATIO_INVERSE
  SMALL_PENALTY_FACTOR = GOLDEN_RATIO_INVERSE**0.5

  # Custom exception for abstract methods
  class AbstractMethodError < NoMethodError; end
end

require "head_music/version"

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/access"
require "humanize"
require "i18n"
require "i18n/backend/fallbacks"

I18n::Backend::Simple.include I18n::Backend::Fallbacks
I18n.load_path << Dir[File.join(File.dirname(__dir__), "lib", "head_music", "locales", "*.yml")]
I18n.config.available_locales = %i[en fr de it ru es en_US en_GB]
I18n.default_locale = :en
I18n.fallbacks[:de] = %i[de en_GB en]
I18n.fallbacks[:en_US] = %i[en_US en en_GB]
I18n.fallbacks[:en_GB] = %i[en_GB en en_US]
I18n.fallbacks[:es] = %i[es en]
I18n.fallbacks[:fr] = %i[fr en_GB en]
I18n.fallbacks[:it] = %i[it en_GB en]
I18n.fallbacks[:ru] = %i[ru en_GB en]

# utilities
require "head_music/utilities/hash_key"

# modules
require "head_music/named"
require "head_music/parsable"

# rudiments
require "head_music/rudiment/base"
require "head_music/rudiment/letter_name"
require "head_music/rudiment/alteration"
require "head_music/rudiment/spelling"
require "head_music/rudiment/rhythmic_unit"
require "head_music/rudiment/rhythmic_value"
require "head_music/rudiment/register"
require "head_music/rudiment/pitch"
require "head_music/rudiment/rhythmic_element"
require "head_music/rudiment/note"
require "head_music/rudiment/unpitched_note"
require "head_music/rudiment/rest"

require "head_music/rudiment/chromatic_interval"
require "head_music/rudiment/clef"
require "head_music/rudiment/consonance"
require "head_music/rudiment/tonal_context"
require "head_music/rudiment/diatonic_context"
require "head_music/rudiment/key"
require "head_music/rudiment/mode"
require "head_music/rudiment/key_signature"
require "head_music/rudiment/key_signature/enharmonic_equivalence"
require "head_music/rudiment/meter"
require "head_music/rudiment/musical_symbol"
require "head_music/rudiment/pitch/enharmonic_equivalence"
require "head_music/rudiment/pitch/octave_equivalence"
require "head_music/rudiment/pitch_class"
require "head_music/rudiment/quality"
require "head_music/rudiment/reference_pitch"
require "head_music/rudiment/rhythm"
require "head_music/rudiment/scale"
require "head_music/rudiment/scale_degree"
require "head_music/rudiment/scale_type"
require "head_music/rudiment/solmization"
require "head_music/rudiment/tempo"
require "head_music/rudiment/tuning"
require "head_music/rudiment/tuning/just_intonation"
require "head_music/rudiment/tuning/meantone"
require "head_music/rudiment/tuning/pythagorean"

# parse
require "head_music/parse/pitch"
require "head_music/parse/rhythmic_value"
require "head_music/parse/rhythmic_element"

# instruments
require "head_music/instruments/instrument_family"
require "head_music/instruments/instrument"
require "head_music/instruments/score_order"
require "head_music/instruments/staff_scheme"
require "head_music/instruments/staff"
require "head_music/instruments/variant"

# content
require "head_music/content/bar"
require "head_music/content/composition"
require "head_music/content/note"
require "head_music/content/placement"
require "head_music/content/position"
require "head_music/content/staff"
require "head_music/content/voice"

# analysis
require "head_music/analysis/circle"
require "head_music/analysis/diatonic_interval"
require "head_music/analysis/diatonic_interval/category"
require "head_music/analysis/diatonic_interval/naming"
require "head_music/analysis/diatonic_interval/parser"
require "head_music/analysis/diatonic_interval/semitones"
require "head_music/analysis/diatonic_interval/size"
require "head_music/analysis/harmonic_interval"
require "head_music/analysis/interval_consonance"
require "head_music/analysis/interval_cycle"
require "head_music/analysis/melodic_interval"
require "head_music/analysis/motion"
require "head_music/analysis/pitch_class_set"
require "head_music/analysis/pitch_set"
require "head_music/analysis/sonority"

# style analysis
require "head_music/style/tradition"
require "head_music/style/modern_tradition"
require "head_music/style/renaissance_tradition"
require "head_music/style/medieval_tradition"
require "head_music/style/analysis"
require "head_music/style/annotation"
require "head_music/style/mark"

# style guidelines
require "head_music/style/guidelines/always_move"
require "head_music/style/guidelines/approach_perfection_contrarily"
require "head_music/style/guidelines/at_least_eight_notes"
require "head_music/style/guidelines/avoid_crossing_voices"
require "head_music/style/guidelines/avoid_overlapping_voices"
require "head_music/style/guidelines/consonant_climax"
require "head_music/style/guidelines/consonant_downbeats"
require "head_music/style/guidelines/diatonic"
require "head_music/style/guidelines/direction_changes"
require "head_music/style/guidelines/end_on_perfect_consonance"
require "head_music/style/guidelines/end_on_tonic"
require "head_music/style/guidelines/frequent_direction_changes"
require "head_music/style/guidelines/limit_octave_leaps"
require "head_music/style/guidelines/moderate_direction_changes"
require "head_music/style/guidelines/mostly_conjunct"
require "head_music/style/guidelines/notes_same_length"
require "head_music/style/guidelines/no_rests"
require "head_music/style/guidelines/no_unisons_in_middle"
require "head_music/style/guidelines/one_to_one"
require "head_music/style/guidelines/prefer_contrary_motion"
require "head_music/style/guidelines/prefer_imperfect"
require "head_music/style/guidelines/prepare_octave_leaps"
require "head_music/style/guidelines/recover_large_leaps"
require "head_music/style/guidelines/singable_intervals"
require "head_music/style/guidelines/singable_range"
require "head_music/style/guidelines/single_large_leaps"
require "head_music/style/guidelines/start_on_perfect_consonance"
require "head_music/style/guidelines/start_on_tonic"
require "head_music/style/guidelines/step_down_to_final_note"
require "head_music/style/guidelines/step_out_of_unison"
require "head_music/style/guidelines/step_to_final_note"
require "head_music/style/guidelines/step_up_to_final_note"
require "head_music/style/guidelines/up_to_fourteen_notes"

# style guides
require "head_music/style/guides/fux_cantus_firmus"
require "head_music/style/guides/modern_cantus_firmus"
require "head_music/style/guides/first_species_melody"
require "head_music/style/guides/first_species_harmony"
