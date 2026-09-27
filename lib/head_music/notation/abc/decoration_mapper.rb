# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Maps ABC decorations to the markings they stand for. A decoration the
  # catalogs hold becomes an articulation, ornament, note dynamic, or level; a
  # standard one they don't hold, such as a fermata or a bowing, is recognized
  # and dropped; anything else is unrecognized.
  #
  # !marcato!, !^!, !sf!, !rfz!, and !fp! are abcm2ps and abc2svg extensions,
  # read leniently.
  module DecorationMapper
    SHORTHANDS = {
      "." => [:articulation, "staccato"],
      "L" => [:articulation, "accent"],
      "T" => [:ornament, "trill"],
      "M" => [:ornament, "mordent"],
      "P" => [:ornament, "inverted_mordent"]
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
      **HeadMusic::Rudiment::Dynamic.levels.to_h { |level| [level.name_key, [:level, level.name_key]] }
    }.freeze

    DROPPED_SHORTHANDS = %w[~ H O S u v].to_set.freeze

    DROPPED_NAMES = %w[
      roll turnx invertedturn invertedturnx arpeggio trill( trill)
      fermata invertedfermata breath upbow downbow open thumb snap slide + plus
      0 1 2 3 4 5 trem1 trem2 trem3 trem4 pppp ffff
      crescendo( crescendo) diminuendo( diminuendo) <( <) >( >)
      segno coda D.S. D.C. dacoda dacapo fine
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
