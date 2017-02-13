require 'spec_helper'

RSpec.describe HeadMusic::Interval do
  let(:perfect_unison) { HeadMusic::Interval.named(:perfect_unison) }
  let(:major_third) { HeadMusic::Interval.named(:major_third) }
  let(:minor_third) { HeadMusic::Interval.named(:minor_third) }
  let(:perfect_fourth) { HeadMusic::Interval.named(:perfect_fourth) }
  let(:perfect_fifth) { HeadMusic::Interval.named(:perfect_fifth) }
  let(:perfect_octave) { HeadMusic::Interval.named(:perfect_octave) }
  let(:perfect_11th) { HeadMusic::Interval.get(17) }

  specify { expect(major_third).to be > minor_third }

  specify { expect(major_third + minor_third).to eq perfect_fifth }

  specify { expect(perfect_fifth - minor_third).to eq major_third }

  specify { expect(perfect_unison).to be_simple }
  specify { expect(major_third).to be_simple }
  specify { expect(perfect_octave).to be_simple }
  specify { expect(perfect_11th).not_to be_simple }

  specify { expect(perfect_unison).not_to be_compound }
  specify { expect(major_third).not_to be_compound }
  specify { expect(perfect_octave).not_to be_compound }
  specify { expect(perfect_11th).to be_compound }

  specify { expect(perfect_11th.simplified).to eq(perfect_fourth) }
end
