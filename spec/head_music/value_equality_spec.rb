require "spec_helper"

describe HeadMusic::ValueEquality do
  let(:value_class) do
    Class.new do
      include HeadMusic::ValueEquality

      attr_reader :name, :size

      value_equality :name, :size

      def initialize(name, size)
        @name = name
        @size = size
      end
    end
  end

  let(:original) { value_class.new("a", 1) }
  let(:same) { value_class.new("a", 1) }
  let(:different) { value_class.new("a", 2) }

  it "is equal when every declared attribute is equal" do
    expect(original).to eq same
  end

  it "is unequal when a declared attribute differs" do
    expect(original).not_to eq different
  end

  it "is unequal to an instance of another class" do
    expect(original).not_to eq Struct.new(:name, :size).new("a", 1)
  end

  it "collapses equal instances as hash keys" do
    expect({original => 1, same => 2}.size).to eq 1
  end

  it "deduplicates equal instances" do
    expect([original, same, different].uniq).to eq [original, different]
  end
end
