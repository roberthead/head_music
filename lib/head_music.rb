require 'head_music/version'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/access'
require 'humanize'

require 'head_music/accidental'
require 'head_music/bar'
require 'head_music/chord'
require 'head_music/circle'
require 'head_music/clef'
require 'head_music/composition'
require 'head_music/consonance'
require 'head_music/functional_interval'
require 'head_music/grand_staff'
require 'head_music/instrument'
require 'head_music/interval'
require 'head_music/key_signature'
require 'head_music/letter_name'
require 'head_music/melodic_interval'
require 'head_music/meter'
require 'head_music/note'
require 'head_music/octave'
require 'head_music/pitch'
require 'head_music/pitch_class'
require 'head_music/placement'
require 'head_music/position'
require 'head_music/quality'
require 'head_music/rhythm'
require 'head_music/rhythmic_unit'
require 'head_music/rhythmic_value'
require 'head_music/scale'
require 'head_music/scale_type'
require 'head_music/spelling'
require 'head_music/staff'

require 'head_music/style/analysis'
require 'head_music/style/annotation'
require 'head_music/style/mark'

require 'head_music/style/rules/always_move'
require 'head_music/style/rules/at_least_eight_notes'
require 'head_music/style/rules/diatonic'
require 'head_music/style/rules/end_on_tonic'
require 'head_music/style/rules/limit_range'
require 'head_music/style/rules/mostly_conjunct'
require 'head_music/style/rules/no_rests'
require 'head_music/style/rules/notes_same_length'
require 'head_music/style/rules/permitted_intervals'
require 'head_music/style/rules/recover_large_leaps'
require 'head_music/style/rules/start_on_tonic'
require 'head_music/style/rules/step_down_to_final_note'
require 'head_music/style/rules/up_to_thirteen_notes'

require 'head_music/style/rulesets/cantus_firmus'

require 'head_music/utilities/hash_key'
require 'head_music/voice'

module HeadMusic
  GOLDEN_RATIO = (1 + 5**0.5) / 2.0
  GOLDEN_RATIO_INVERSE = 1 / GOLDEN_RATIO
  PENALTY_FACTOR = GOLDEN_RATIO_INVERSE
  SMALL_PENALTY_FACTOR = GOLDEN_RATIO_INVERSE**0.5
end
