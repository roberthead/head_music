# frozen_string_literal: true

require "spec_helper"

RSpec.describe HeadMusic::Rudiment::DiatonicContext do
  describe "initialization" do
    it "requires a tonic spelling argument" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe "abstract methods" do
    subject(:instance) { described_class.new("C") }

    it "raises an error when abstract methods are called" do
      expect { instance.scale_type }.to raise_error(NotImplementedError)
      expect { instance.relative }.to raise_error(NotImplementedError)
      expect { instance.parallel }.to raise_error(NotImplementedError)
    end
  end
end
