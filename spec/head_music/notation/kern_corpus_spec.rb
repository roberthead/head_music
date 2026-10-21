require "spec_helper"

# A sweep of the Bach chorales, run only when KERN_CORPUS names a local clone
# of them (see KernCorpus).
describe HeadMusic::Notation::Kern, oracle: :kern_corpus do
  corpus = KernCorpus.directory
  unreadable = KernCorpus::UNREADABLE

  KernCorpus.paths.each do |path|
    name = File.basename(path)

    if unreadable.key?(name)
      it "refuses #{name}" do
        expect { described_class.parse(File.read(path)) }.to raise_error { |error| expect(error.class).to eq unreadable.fetch(name) }
      end
    else
      it "reads #{name}, writes it back to itself, and renders it" do
        flow = described_class.parse(File.read(path))
        expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
        expect([flow.to_musicxml, flow.to_lilypond]).to all(be_a(String))
      end

      # Every chorale ends its phrases with fermatas, and those in 4/4 are
      # written in common time.
      it "reads the fermatas and the meter's sign of #{name}" do
        source = File.read(path)
        flow = described_class.parse(source)
        expect(flow.fermatas).not_to be_empty
        expect(flow.meter.symbol).to eq(source.include?("*met(c)") ? :common : nil)
      end
    end
  end

  it "finds the corpus" do
    expect(Dir[File.join(corpus, "kern", "*.krn")].length).to eq 370
  end
end
