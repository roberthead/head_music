module HeadMusic::Instruments; end

# DEPRECATED: GenericInstrument is now a facade for Instrument.
#
# This class is kept for backward compatibility. New code should use
# HeadMusic::Instruments::Instrument directly.
#
# A generic musical instrument representing a species like trumpet or clarinet.
# Now delegates to Instrument which supports parent-based inheritance.
#
# @see HeadMusic::Instruments::Instrument
class HeadMusic::Instruments::GenericInstrument
  class << self
    def get(name)
      HeadMusic::Instruments::Instrument.get(name)
    end

    def all
      HeadMusic::Instruments::Instrument.all
    end
  end
end
