require "spec_helper"

describe HeadMusic::Content::Project do
  describe "credits" do
    let(:project) do
      described_class.new(name: "Arranged Set").tap do |project|
        project.add_credit("Andrés Segovia", :arranger)
        project.add_credit("A. Transcriber", :transcriber)
      end
    end

    it "starts empty" do
      expect(described_class.new.credits).to be_empty
    end

    it "holds this version's people" do
      expect(project.credits.names(:arranger)).to eq ["Andrés Segovia"]
    end

    it "serializes the credits" do
      expect(project.to_h["credits"].map { |credit| credit["role"] }).to eq %w[arranger transcriber]
    end

    it "round-trips them" do
      expect(described_class.from_h(project.to_h).credits.names(:arranger)).to eq ["Andrés Segovia"]
    end

    it "rejects a composer credit at the project level" do
      expect { project.add_credit("J. S. Bach", :composer) }
        .to raise_error(ArgumentError, "composer is a work role, not a project role")
    end
  end

  describe "#works" do
    let(:work) do
      HeadMusic::Content::Work.new(
        title: "Cello Suite No. 1",
        catalog_number: "BWV 1007",
        credits: [HeadMusic::Content::Credit.new(person: "Johann Sebastian Bach", role: :composer)]
      )
    end
    let(:project) do
      described_class.new(name: "Suite").tap do |project|
        %w[Prelude Allemande].each do |name|
          flow = HeadMusic::Content::Flow.new(name: name, work: work)
          flow.add_voice.place("1:1", :whole, "G3")
          project.add_flow(flow)
        end
      end
    end

    it "counts one work across two flows citing it" do
      expect(project.works.size).to eq 1
    end

    it "restores both citations as equal works" do
      restored = described_class.from_h(project.to_h)
      expect(restored.flows[0].work).to eq restored.flows[1].work
      expect(restored.works.size).to eq 1
    end

    it "round-trips losslessly" do
      expect(described_class.from_h(project.to_h).to_h).to eq project.to_h
    end

    it "is empty when no flow cites a work" do
      expect(described_class.new.works).to eq []
    end
  end

  it "reads a 21.0.0-shaped document that names no credits and no works" do
    hash = {"schema_version" => 4, "name" => "Old", "players" => [], "flows" => []}
    project = described_class.from_h(hash)
    expect(project.credits).to be_empty
    expect(project.works).to eq []
  end
end
