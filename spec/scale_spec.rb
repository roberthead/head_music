require 'spec_helper'

describe Scale do
  let(:root_pitch) { Pitch.get("D4") }
  subject(:scale) { Scale.get(root_pitch) }

  its(:pitch_names) { are_expected.to eq %w[D E F# G A B C# D] }
end
