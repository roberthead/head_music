# A module for musical content
module HeadMusic::Content; end

# A D.C. or D.S. instruction, and where the replay ends: at the Fine, at the
# To Coda, or, with no target named, at whichever of the two comes first.
class HeadMusic::Content::Jump < Data.define(:kind, :to)
  KINDS = %i[da_capo dal_segno].freeze
  TARGETS = [nil, :fine, :coda].freeze
  ABBREVIATIONS = {da_capo: "D.C.", dal_segno: "D.S."}.freeze
  PATTERN = /\A\s*(?:(?<kind>D\.\s*C\.|Da\s+Capo|D\.\s*S\.|Dal\s+Segno))(?:\s+al\s+(?<to>Fine|Coda))?\s*\z/i

  def self.new(kind, to: nil)
    super(kind: kind, to: to)
  end

  def self.from_h(hash)
    values = hash.transform_keys(&:to_s)
    new(values["kind"], to: values["to"])
  end

  def self.get(text)
    match = PATTERN.match(text.to_s)
    return unless match

    kind = match[:kind].downcase.delete(". ").start_with?("dc", "dacapo") ? :da_capo : :dal_segno
    new(kind, to: match[:to]&.downcase)
  end

  def initialize(kind:, to:)
    kind = kind&.to_sym
    to = to&.to_sym
    raise ArgumentError, "unknown jump kind #{kind.inspect}" unless KINDS.include?(kind)
    raise ArgumentError, "unknown jump target #{to.inspect}" unless TARGETS.include?(to)

    super
  end

  def da_capo?
    kind == :da_capo
  end

  def dal_segno?
    kind == :dal_segno
  end

  def to_s
    [ABBREVIATIONS[kind], to && "al #{to.to_s.capitalize}"].compact.join(" ")
  end

  def to_h
    {"kind" => kind.to_s, "to" => to&.to_s}.compact
  end
end
