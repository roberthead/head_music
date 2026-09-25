require "spec_helper"

# A sweep of a real kern corpus, run only when KERN_CORPUS names a local
# clone of https://github.com/craigsapp/bach-370-chorales. The corpus is
# CC BY-NC-SA 4.0, so none of it is committed here.
#
# Four chorales hold a bar the model cannot: two a short bar in the middle
# of the piece, one a 3/4 bar in 4/4 with a meter change inside the merged
# bar, and one an eight-beat bar.
describe HeadMusic::Notation::Kern do
  corpus = ENV["KERN_CORPUS"]
  unreadable = {
    "chor011.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError,
    "chor130.krn" => HeadMusic::Notation::Kern::ParseError,
    "chor197.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError,
    "chor280.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError
  }

  before { skip "set KERN_CORPUS to a local clone of the Bach chorales" unless corpus }

  (corpus ? Dir[File.join(corpus, "kern", "*.krn")].sort : []).each do |path|
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
    end
  end

  it "finds the corpus" do
    expect(Dir[File.join(corpus, "kern", "*.krn")].length).to eq 370
  end
end
