require 'spec_helper'

describe Note do
  subject(:note) { Note.new("F#5", :quarter) }

  its(:pitch) { is_expected.to eq 'F#5' }
  its(:duration) { is_expected.to eq 0.25 }
end
