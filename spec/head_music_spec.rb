# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic do
  it 'has a three-digit version number' do
    expect(HeadMusic::VERSION).not_to be nil
    expect(HeadMusic::VERSION).to be =~ /\d+\.\d+\.\d+/
  end

  it 'defines the golden ratio' do
    expect(HeadMusic::GOLDEN_RATIO).to be_within(0.001).of(1.618)
    expect(HeadMusic::PENALTY_FACTOR).to be_within(0.001).of(0.618)
  end
end
