# frozen_string_literal: true

module HeadMusic
  GOLDEN_RATIO = (1 + 5**0.5) / 2.0
  GOLDEN_RATIO_INVERSE = 1 / GOLDEN_RATIO
  PENALTY_FACTOR = GOLDEN_RATIO_INVERSE
  SMALL_PENALTY_FACTOR = GOLDEN_RATIO_INVERSE**0.5
end

require 'head_music/version'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/access'
require 'humanize'
require 'i18n'
require 'i18n/backend/fallbacks'

I18n::Backend::Simple.include I18n::Backend::Fallbacks
I18n.load_path << Dir[File.join(File.dirname(__dir__), 'lib', 'head_music', 'locales', '*.yml')]
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
require 'head_music/utilities/hash_key'

# modules
require 'head_music/named'

# rudiments
require 'head_music/chromatic_interval'
require 'head_music/circle'
require 'head_music/clef'
require 'head_music/consonance'
require 'head_music/diatonic_interval'
require 'head_music/grand_staff'
require 'head_music/harmonic_interval'
require 'head_music/instrument'
require 'head_music/interval_cycle'
require 'head_music/key_signature'
require 'head_music/letter_name'
require 'head_music/melodic_interval'
require 'head_music/meter'
require 'head_music/motion'
require 'head_music/musical_symbol'
require 'head_music/pitch'
require 'head_music/pitch/enharmonic_equivalence'
require 'head_music/pitch/octave_equivalence'
require 'head_music/pitch_class'
require 'head_music/pitch_class_set'
require 'head_music/pitch_set'
require 'head_music/quality'
require 'head_music/reference_pitch'
require 'head_music/register'
require 'head_music/rhythm'
require 'head_music/rhythmic_unit'
require 'head_music/scale'
require 'head_music/scale_degree'
require 'head_music/scale_type'
require 'head_music/sign'
require 'head_music/solmization'
require 'head_music/sonority'
require 'head_music/spelling'
require 'head_music/staff'
require 'head_music/tuning'

# content
require 'head_music/content/bar'
require 'head_music/content/composition'
require 'head_music/content/note'
require 'head_music/content/placement'
require 'head_music/content/position'
require 'head_music/content/rhythmic_value'
require 'head_music/content/voice'

# analysis
require 'head_music/style/analysis'
require 'head_music/style/annotation'
require 'head_music/style/mark'

# guidelines
require 'head_music/style/guidelines/always_move'
require 'head_music/style/guidelines/approach_perfection_contrarily'
require 'head_music/style/guidelines/at_least_eight_notes'
require 'head_music/style/guidelines/avoid_crossing_voices'
require 'head_music/style/guidelines/avoid_overlapping_voices'
require 'head_music/style/guidelines/consonant_climax'
require 'head_music/style/guidelines/consonant_downbeats'
require 'head_music/style/guidelines/diatonic'
require 'head_music/style/guidelines/direction_changes'
require 'head_music/style/guidelines/end_on_perfect_consonance'
require 'head_music/style/guidelines/end_on_tonic'
require 'head_music/style/guidelines/frequent_direction_changes'
require 'head_music/style/guidelines/limit_octave_leaps'
require 'head_music/style/guidelines/moderate_direction_changes'
require 'head_music/style/guidelines/mostly_conjunct'
require 'head_music/style/guidelines/notes_same_length'
require 'head_music/style/guidelines/no_rests'
require 'head_music/style/guidelines/no_unisons_in_middle'
require 'head_music/style/guidelines/one_to_one'
require 'head_music/style/guidelines/prefer_contrary_motion'
require 'head_music/style/guidelines/prefer_imperfect'
require 'head_music/style/guidelines/prepare_octave_leaps'
require 'head_music/style/guidelines/recover_large_leaps'
require 'head_music/style/guidelines/singable_intervals'
require 'head_music/style/guidelines/singable_range'
require 'head_music/style/guidelines/single_large_leaps'
require 'head_music/style/guidelines/start_on_perfect_consonance'
require 'head_music/style/guidelines/start_on_tonic'
require 'head_music/style/guidelines/step_down_to_final_note'
require 'head_music/style/guidelines/step_out_of_unison'
require 'head_music/style/guidelines/step_to_final_note'
require 'head_music/style/guidelines/step_up_to_final_note'
require 'head_music/style/guidelines/up_to_fourteen_notes'

# guides
require 'head_music/style/guides/fux_cantus_firmus'
require 'head_music/style/guides/modern_cantus_firmus'
require 'head_music/style/guides/first_species_melody'
require 'head_music/style/guides/first_species_harmony'
