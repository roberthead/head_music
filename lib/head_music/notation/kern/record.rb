# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One line of a Humdrum file. Global records (reference records and
  # global comments) span the line and hold it as their only field; every
  # other record holds one field per spine.
  Record = Data.define(:kind, :line, :fields) do
    def global?
      %i[universal reference global_comment].include?(kind)
    end

    # The key of a reference record ("COM" for "!!!COM: Bach"), or nil.
    def reference_key
      reference_match&.[](1)&.strip
    end

    def reference_value
      reference_match&.[](2)&.strip
    end

    private

    def reference_match
      /\A!!!([^:]*):\s*(.*)\z/.match(fields.first) if kind == :reference
    end
  end
end
