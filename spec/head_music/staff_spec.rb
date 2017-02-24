require 'spec_helper'

describe Staff do
  subject { Staff.new(:treble) }

  its(:clef) { is_expected.to eq :treble }
  its(:line_count) { is_expected.to be 5 }
end
