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

  its(:articulations) { is_expected.to eq [] }
  its(:ornaments) { is_expected.to eq [] }
  its(:note_dynamic) { is_expected.to be_nil }

  it "refuses an articulation" do
    expect { rest.articulate(:staccato) }
      .to raise_error(ArgumentError, "a rest cannot be articulated; the articulation at 1:1:000 needs a note")
  end

  it "refuses an ornament" do
    expect { rest.embellish(:trill) }
      .to raise_error(ArgumentError, "a rest cannot be ornamented; the ornament at 1:1:000 needs a note")
  end

  it "refuses a note dynamic" do
    expect { rest.note_dynamic = :sfz }
      .to raise_error(ArgumentError, "a rest cannot be accented; the dynamic at 1:1:000 needs a note")
  end
end
