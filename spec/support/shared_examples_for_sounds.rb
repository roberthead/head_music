RSpec.shared_examples "a sound" do
  it "responds to pitched? with a boolean" do
    expect(subject.pitched?).to be(true).or be(false)
  end

  it "returns a non-empty String from to_s" do
    expect(subject.to_s).to be_a(String)
    expect(subject.to_s).not_to be_empty
  end

  it "equals itself by both == and eql?" do
    same = subject
    expect(subject == same).to be true
    expect(subject.eql?(same)).to be true
  end

  it "does not equal an unrelated object by either == or eql?" do
    other = Object.new
    expect(subject == other).to be false
    expect(subject.eql?(other)).to be false
  end

  it "computes the same hash for equal objects" do
    same = subject
    expect(subject.hash).to eq same.hash
  end
end
