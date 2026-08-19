require "spec_helper"

describe HeadMusic::Rudiment::Base do
  it "cannot be instantiated" do
    expect { described_class.new }.to raise_error(NotImplementedError, "Cannot instantiate abstract rudiment base class")
  end

  describe "the registry" do
    subject(:rudiment_class) do
      Class.new(described_class) do
        attr_reader :number

        def self.get(number)
          fetch_or_register(number)
        end

        def initialize(number)
          @number = number
        end
      end
    end

    it "answers with the same instance for the same key" do
      first_lookup = rudiment_class.get(1)

      expect(rudiment_class.get(1)).to be first_lookup
    end

    it "answers with a different instance for a different key" do
      expect(rudiment_class.get(1)).not_to be rudiment_class.get(2)
    end

    # The hand-rolled registries each had to remember to initialize their own
    # hash, and Register.default was the one that forgot: it raised on the
    # first lookup of a process until something else had populated it.
    it "registers without the class having primed anything" do
      expect { rudiment_class.get(1) }.not_to raise_error
    end

    it "keeps a subclass's instances out of the parent's registry" do
      subclass = Class.new(rudiment_class)

      expect(subclass.get(1)).not_to be rudiment_class.get(1)
    end
  end
end
