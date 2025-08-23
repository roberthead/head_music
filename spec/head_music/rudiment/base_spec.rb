require "spec_helper"

describe HeadMusic::Rudiment::Base do
  it "cannot be instantiated" do
    expect { described_class.new }.to raise_error(NotImplementedError, "Cannot instantiate abstract rudiment base class")
  end
end
