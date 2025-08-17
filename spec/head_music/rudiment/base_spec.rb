require "spec_helper"

describe HeadMusic::Rudiment::Base do
  describe "instantiation" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe "inheritance" do
    it "is a class" do
      expect(described_class).to be_a(Class)
    end

    it "provides a base for rudiment classes" do
      test_class = Class.new(described_class)
      instance = test_class.new
      expect(instance).to be_a(described_class)
    end
  end
end
