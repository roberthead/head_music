require "spec_helper"

describe HeadMusic::Content::RestEvent do
  subject(:rest) { described_class.new(voice, "1:1", :quarter) }

  let(:voice) { HeadMusic::Content::Flow.new.add_voice }

  it { is_expected.to be_a HeadMusic::Content::VoiceEvent }
  it { is_expected.to be_rest }
  it { is_expected.not_to be_sounded }
  it { is_expected.not_to be_sung }

  its(:sounds) { is_expected.to eq [] }
  its(:pitch) { is_expected.to be_nil }
  its(:syllables) { is_expected.to eq({}) }
  its(:to_s) { is_expected.to eq "quarter rest at 1:1:000" }

  it "refuses a syllable" do
    expect { rest.sing("la") }.to raise_error(ArgumentError, "a rest cannot sing; the syllable at 1:1:000 needs a note")
  end
end
