class HeadMusic::Content::Flow
  # The staff-system corner of SchemaValues: a system, its bracket, its
  # staves, and each staff's opening clef and clef changes. Split from the
  # scalar validators only because the two together outgrew one class.
  class StaffSystemValues
    # @param values [SchemaValues] for the bar numbers of clef changes
    def initialize(values)
      @values = values
    end

    # A staff system serializes as its bracket and, for each staff, its opening
    # clef and clef changes; a clef of null is a staff whose clef was never
    # authored, which the writers infer from the voice instead.
    def staff_system(value, path)
      return nil if value.nil?
      raise ArgumentError, "#{path}: staff_system must be a Hash, got #{value.inspect}" unless value.is_a?(Hash)

      staves = Array(value["staves"]).each_with_index.map do |staff_hash, index|
        staff(staff_hash, "#{path}.staves[#{index}]")
      end
      HeadMusic::Content::StaffSystem.new(staves: staves, bracket: bracket(value["bracket"], path))
    end

    def staff(value, path)
      raise ArgumentError, "#{path}: staff must be a Hash, got #{value.inspect}" unless value.is_a?(Hash)

      HeadMusic::Content::Staff.new(clef: clef(value["clef"], path)).tap do |staff|
        Array(value["clef_changes"]).each_with_index do |change, index|
          change_path = "#{path}.clef_changes[#{index}]"
          staff.change_clef(values.bar_number(change, index, "#{path}.clef_changes"), clef_change(change["clef"], change_path))
        end
      end
    end

    private

    attr_reader :values

    def bracket(value, path)
      return :none if value.nil?

      symbol = value.to_sym
      raise ArgumentError, "#{path}: unknown bracket #{value.inspect}" unless HeadMusic::Content::StaffSystem::BRACKETS.include?(symbol)

      symbol
    end

    def clef(value, path)
      return nil if value.nil?

      clef = begin
        HeadMusic::Rudiment::Clef.get(value)
      rescue
        nil
      end
      raise ArgumentError, "#{path}: unknown clef #{value.inspect}" if clef&.pitch.nil?

      clef
    end

    # Unlike an opening clef, a change to no clef means nothing: there is no
    # "stop having a clef" in notation.
    def clef_change(value, path)
      raise ArgumentError, "#{path}: a clef change names a clef, got nil" if value.nil?

      clef(value, path)
    end
  end
end
