require "spec_helper"

describe HeadMusic::Notation::ABC::PendingGraces do
  subject(:graces) { described_class.new(slurs) }

  let(:slurs) { HeadMusic::Notation::ABC::PendingSlurs.new(nil) }

  it "hands over the grace notes once" do
    graces.add(%i[first second])
    expect([graces.take, graces.take]).to eq [%i[first second], []]
  end

  it "starts a slur opened before them on the first of them" do
    slurs.open
    graces.add([:grace])
    expect(slurs.take).to eq [:grace_open]
  end

  it "leaves a slur alone when there are no grace notes" do
    slurs.open
    graces.add([])
    expect(slurs.take).to eq [:open]
  end

  it "starts the slur on what comes next once they are dropped" do
    slurs.open
    graces.add([:grace])
    graces.drop
    expect([graces.take, slurs.take]).to eq [[], [:open]]
  end
end
