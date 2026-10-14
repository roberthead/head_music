# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Maps ABC decorations to the markings they stand for. A decoration the
  # catalogs hold becomes an articulation, ornament, note dynamic, level, or
  # hairpin start or end; a navigation sign or instruction marks its bar; a
  # standard one they don't hold, such as a fermata or a bowing, is recognized
  # and dropped; anything else is unrecognized.
  #
  # !marcato!, !^!, !sf!, !rfz!, !fp!, and the !D.C.alfine! family are abcm2ps
  # and abc2svg extensions, read leniently.
  module DecorationMapper
    # A navigation key is a bar flag, or text that Jump.get reads.
    NAVIGATION = {
      "segno" => "segno",
      "coda" => "coda",
      "fine" => "fine",
      "dacoda" => "to_coda",
      "D.C." => "D.C.",
      "dacapo" => "D.C.",
      "D.S." => "D.S.",
      "D.C.alfine" => "D.C. al Fine",
      "D.C.alcoda" => "D.C. al Coda",
      "D.S.alfine" => "D.S. al Fine",
      "D.S.alcoda" => "D.S. al Coda"
    }.freeze

    SHORTHANDS = {
      "." => [:articulation, "staccato"],
      "L" => [:articulation, "accent"],
      "T" => [:ornament, "trill"],
      "M" => [:ornament, "mordent"],
      "P" => [:ornament, "inverted_mordent"],
      "S" => [:navigation, "segno"],
      "O" => [:navigation, "coda"]
    }.freeze

    NAMED = {
      "staccato" => [:articulation, "staccato"],
      "wedge" => [:articulation, "staccatissimo"],
      "accent" => [:articulation, "accent"],
      ">" => [:articulation, "accent"],
      "emphasis" => [:articulation, "accent"],
      "tenuto" => [:articulation, "tenuto"],
      "marcato" => [:articulation, "marcato"],
      "^" => [:articulation, "marcato"],
      "trill" => [:ornament, "trill"],
      "lowermordent" => [:ornament, "mordent"],
      "mordent" => [:ornament, "mordent"],
      "uppermordent" => [:ornament, "inverted_mordent"],
      "pralltriller" => [:ornament, "inverted_mordent"],
      "turn" => [:ornament, "turn"],
      **HeadMusic::Rudiment::Dynamic.accents.to_h { |accent| [accent.name_key, [:note_dynamic, accent.name_key]] },
      **HeadMusic::Rudiment::Dynamic.levels.to_h { |level| [level.name_key, [:level, level.name_key]] },
      **NAVIGATION.transform_values { |key| [:navigation, key] },
      "<(" => [:hairpin_start, "crescendo"],
      "<)" => [:hairpin_end, "crescendo"],
      ">(" => [:hairpin_start, "diminuendo"],
      ">)" => [:hairpin_end, "diminuendo"],
      "crescendo(" => [:hairpin_start, "crescendo"],
      "crescendo)" => [:hairpin_end, "crescendo"],
      "diminuendo(" => [:hairpin_start, "diminuendo"],
      "diminuendo)" => [:hairpin_end, "diminuendo"]
    }.freeze

    DROPPED_SHORTHANDS = %w[~ H u v].to_set.freeze

    DROPPED_NAMES = %w[
      roll turnx invertedturn invertedturnx arpeggio trill( trill)
      fermata invertedfermata breath upbow downbow open thumb snap slide + plus
      0 1 2 3 4 5 trem1 trem2 trem3 trem4 pppp ffff
      shortphrase mediumphrase longphrase editorial courtesy
    ].to_set.freeze

    module_function

    # Returns {kind:, key:} for a marking, {kind: :dropped, key: nil} for a
    # decoration recognized and dropped, or nil for one not recognized at all.
    # "+trill+" is the ABC 2.0 spelling of "!trill!".
    def classify(lexeme)
      if delimited?(lexeme)
        lookup(lexeme[1..-2], NAMED, DROPPED_NAMES)
      else
        lookup(lexeme, SHORTHANDS, DROPPED_SHORTHANDS)
      end
    end

    def delimited?(lexeme)
      lexeme.length > 2 && %w[! +].include?(lexeme[0]) && lexeme[-1] == lexeme[0]
    end

    def lookup(name, markings, dropped)
      kind, key = markings[name]
      return {kind: kind, key: key} if kind

      {kind: :dropped, key: nil} if dropped.include?(name)
    end
  end
end
