require "spec_helper"

# Every customer-facing string a guide item can produce, pinned before those
# strings moved into locale files.
#
# Deliberately a literal table rather than a generated comparison: a diff here
# is a sentence a student reads changing, which should be a decision someone
# made rather than something a refactor did quietly. The story lists the
# entries that change and why.
#
# Each row is a guideline, the configuration a guide gives it, and the
# violation message that pair renders.
GUIDE_ITEM_STRINGS = [
  ["AllowWholeHalfQuarterNotes", {}, "Use only whole notes, half notes, and quarter notes."],
  ["AllowFifthSpeciesRhythmicValues", {}, "Use only whole notes in the final bar, half notes, quarter notes, and paired stepwise eighth notes on weak beats."],
  ["AllowFreeSpeciesRhythmicValues", {}, "Use only whole notes, half notes, quarter notes, and paired stepwise eighth notes on weak beats."],
  ["AlwaysMove", {}, "Always move to a different note."],
  ["AlwaysMove", {restruck_suspensions: true}, "Always move to a different note, except to strike a suspension again."],
  ["ApproachPerfectionContrarily", {}, "Approach perfect consonances by contrary motion."],
  ["AvoidCrossingVoices", {}, "Avoid crossing voices. Maintain the high-low relationship between voices."],
  ["AvoidOverlappingVoices", {}, "Avoid overlapping voices. Maintain the high-low relationship between voices even for adjacent notes."],
  ["BeginCambiataOnDownbeat", {}, "Begin the nota cambiata on the downbeat."],
  ["ClausulaVera", {}, "Close with the clausula vera: the leading tone and the second degree, a minor third or major sixth apart, stepping in contrary motion to the tonic in an octave or unison."],
  ["ConsonantClimax", {}, "Peak once, or twice with a step between."],
  ["ConsonantDownbeats", {}, "Use consonant harmonic intervals on every downbeat (unless a tied suspension)."],
  ["ConsonantDownbeats", {restruck_suspensions: true}, "Use consonant harmonic intervals on every downbeat (unless a suspension, tied or struck again)."],
  ["ContinueAfterDoubleNeighbor", {}, "Continue by step in the same direction after a double neighbor."],
  ["Contoured", {contour: :arch}, "Write a melody with the arch contour."],
  ["Contoured", {contour: :ascending}, "Write a melody with the ascending contour."],
  ["Contoured", {contour: :descending}, "Write a melody with the descending contour."],
  ["Contoured", {contour: :static}, "Write a melody with the static contour."],
  ["Contoured", {contour: :valley}, "Write a melody with the valley contour."],
  ["Contoured", {contour: :wave}, "Write a melody with the wave contour."],
  ["Diatonic", {}, "Use only notes in the key signature."],
  ["EmbellishedSuspensionTreatment", {}, "Prepare each suspension as a consonance and resolve it downward by step halfway through the bar, however the resolution is delayed or decorated."],
  ["EndOnTonic", {}, "End on the first scale degree."],
  ["FirstBarHalfNotes", {}, "Begin the first bar with half notes, or enter after a half rest."],
  ["FirstBarQuarterNotes", {}, "Begin the first bar with quarter notes, or enter after a quarter rest."],
  ["FirstBarWholeNote", {}, "Begin with a whole note in the first bar."],
  ["FloridDissonanceTreatment", {}, "Treat each dissonance as a passing tone, a neighbor tone, a cambiata, or a double neighbor."],
  ["FourPerBar", {}, "Use four quarter notes in each middle bar."],
  ["FreeDissonanceTreatment", {}, "Explain each dissonance as a figure in either voice or as a prepared suspension resolving down by step; attack no dissonance on a downbeat."],
  ["FrequentDirectionChanges", {}, "Change melodic direction frequently."],
  ["IndependentTextures", {}, "Give the voices different textures; they may share one species texture for no more than two bars."],
  ["LargeLeaps", {violation_key: "guidelines.large_leaps.violations.fux_cantus_firmus", minimum: :perfect_fourth, descending: {minimum: :perfect_fourth, forbidden: :minor_sixth}, recovery: [:consonant_triad, :opposite_step]}, "Recover large leaps by step in the opposite direction."],
  ["LargeLeaps", {minimum: :perfect_fourth, recovery: [:consonant_triad, :any_step, :repetition, :opposite_leap_within]}, "Recover leaps by step, repetition, opposite direction, or spelling triad."],
  ["LimitOctaveLeaps", {}, "Use a maximum of one octave leap."],
  ["MaximumNotes", {maximum: 14}, "Write up to fourteen notes."],
  ["MaximumNotes", {maximum: 32}, "Write up to thirty-two notes."],
  ["MinimumMelodicIntervals", {minimum: 1}, "Write at least one melodic interval."],
  ["MinimumMelodicIntervals", {minimum: 2}, "Write at least two melodic intervals."],
  ["MinimumNotes", {minimum: 3}, "Write at least three notes."],
  ["MinimumNotes", {minimum: 5}, "Write at least five notes."],
  ["MinimumNotes", {minimum: 8}, "Write at least eight notes."],
  ["MixSpeciesTextures", {}, "Mix the textures of the first four species; no one of them may run on for more than two bars."],
  ["ModerateDirectionChanges", {}, "Change melodic direction occasionally."],
  ["MostlyConjunct", {}, "Use mostly conjunct motion."],
  ["NoParallelPerfectAcrossBarline", {}, "Avoid parallel perfect consonances from weak beat to the following downbeat."],
  ["NoParallelPerfectOnDownbeats", {}, "Avoid parallel perfect consonances on consecutive downbeats."],
  ["NoParallelPerfectWithSyncopation", {}, "Avoid parallel perfect consonances between syncopated notes."],
  ["NoRests", {}, "Place a note in each measure."],
  ["NoRestsAfterNote", {}, "Do not rest after the first note has sounded."],
  ["NoStrongBeatUnisons", {}, "Avoid unisons on strong beats except at the beginning and end."],
  ["NoUnisonsInMiddle", {}, "Use a unison only on the first or the last note."],
  ["NoteFillsFinalBar", {}, "End with a single note that fills the final bar."],
  ["NotesSameLength", {}, "Use the same rhythmic value throughout."],
  ["OnePerBar", {}, "Use one whole note in each middle bar."],
  ["OneToOne", {}, "Place a note for each note in the other voice."],
  ["OneToOneWithTies", {}, "Place one note per cantus firmus note. Notes may sustain across the barline."],
  ["PreferContraryMotion", {}, "Prefer contrary motion. Move voices in different melodic directions."],
  ["PreferLongBeforeShort", {}, "Put the longer note before the shorter ones unless it ties forward."],
  ["PreferImperfect", {}, "Prefer imperfect harmonic intervals."],
  ["PrepareOctaveLeaps", {}, "Approach and leave an octave leap from inside the octave."],
  ["SecondSpeciesBreak", {}, "Use only passing tones when breaking the syncopated texture, and break it rarely."],
  ["SetAgainstAnotherVoice", {}, "Set this voice against another voice."],
  ["SingableIntervals", {}, "Use only P1, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line."],
  ["SingableIntervals", {ascending: ["P1", "m2", "M2", "m3", "M3", "P4", "P5", "m6", "M6", "P8"], descending: ["P1", "m2", "M2", "m3", "M3", "P4", "P5", "m6", "M6", "P8"]}, "Use only P1, m2, M2, m3, M3, P4, P5, m6, M6, P8 in the melodic line."],
  ["SingableRange", {}, "Limit melodic range to a tenth."],
  ["StartOnPerfectConsonance", {}, "Start on the tonic or a perfect consonance above the tonic (unless bass voice)."],
  ["StartOnTonic", {}, "Start on the first scale degree."],
  ["StepDownToFinalNote", {}, "Step down to the final note."],
  ["StepOutOfUnison", {}, "Exit a unison by step."],
  ["StepToFinalNote", {}, "Step to the final note."],
  ["StepUpToFinalNote", {}, "Step up to the final note."],
  ["SuspensionTreatment", {}, "Prepare each suspension as a consonance and resolve it downward by step."],
  ["SustainAcrossBarlines", {}, "Sustain a note across the barline into most downbeats, breaking the syncopation only rarely."],
  ["ThirdSpeciesDissonanceTreatment", {}, "Treat each dissonance as a passing tone, a neighbor tone, a cambiata, or a double neighbor."],
  ["ThreePerBar", {}, "Use three quarter notes in each middle bar."],
  ["TripleMeterDissonanceTreatment", {}, "Treat dissonances as passing tones or neighbor tones."],
  ["TwoPerBar", {}, "Use two half notes in each middle bar."],
  ["WeakBeatDissonanceTreatment", {}, "Use only passing tones for dissonances on the weak beat."]
].freeze

describe HeadMusic::Style::GuideItem do
  GUIDE_ITEM_STRINGS.each do |guideline_name, config, expected|
    label = config.empty? ? guideline_name : "#{guideline_name} #{config.inspect}"

    # Pinned in en explicitly rather than in the ambient locale. Harmless while
    # en_GB differed from en by five spellings; a real hazard now that it
    # carries its own note vocabulary and these sentences would come out
    # British.
    it "renders the violation message for #{label}" do
      guideline = HeadMusic::Style::Guidelines.const_get(guideline_name)

      rendered = I18n.with_locale(:en) { described_class.new(guideline, config).violation_preview }

      expect(rendered).to eq expected
    end
  end

  it "pins every distinct guide item in the registry" do
    declared = HeadMusic::Style::Guide::ALL.flat_map(&:guide_items).uniq

    expect(declared.length).to eq GUIDE_ITEM_STRINGS.length
  end
end
