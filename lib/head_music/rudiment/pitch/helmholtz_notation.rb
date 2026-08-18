class HeadMusic::Rudiment::Pitch
  # Helmholtz pitch notation, in which the register is spelled by the case of
  # the letter and the marks after it: C,, C, C c c' c''.
  class HelmholtzNotation
    attr_reader :spelling, :register

    def initialize(spelling, register)
      @spelling = spelling
      @register = HeadMusic::Rudiment::Register.get(register)
    end

    def to_s
      cased_spelling + register.helmholtz_marks
    end

    private

    def cased_spelling
      return spelling.to_s.downcase if register.helmholtz_case == :lower

      spelling.to_s
    end
  end
end
