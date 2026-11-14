require "spec_helper"

# A \new Staff outside a group is one part however many voices it holds. With
# several, its instrumentName names the part's instrument and each voice's
# own name its role; with one, the staff's name is still the voice's role.
describe HeadMusic::Notation::LilyPond do
  def parts(source)
    described_class.parse(source).parts.map { |part| [part.instrument&.name_key, part.voices.map(&:role)] }
  end

  def two_voices(staff_name, *voice_names, opening: "")
    voices = voice_names.map { |name| name ? %(\\new Voice = "#{name}" { #{opening} c''1 }) : "\\new Voice { #{opening} e'1 }" }
    %(\\new Staff \\with { instrumentName = "#{staff_name}" } << #{voices.join(" ")} >>)
  end

  def written(flow)
    project = HeadMusic::Content::Project.new(name: flow.name.to_s).tap { |adopting| adopting.add_flow(flow) }
    project.add_layout(kind: :score, concert_pitch: false).realize(flow)
  end

  def two_voice_flow(instrument, roles)
    HeadMusic::Content::Flow.new(name: "Shared", meter: "4/4", key_signature: "D major").tap do |flow|
      part = flow.add_part(instrument: instrument)
      roles.zip(%w[D5 F♯4]).each { |role, pitch| part.add_voice(role: role).place("1:1", :whole, pitch) }
    end
  end

  def music(flow)
    flow.parts.map { |part| [part.instrument&.name_key, part.voices.map { |voice| [voice.role, voice.pitches.map(&:to_s)] }] }
  end

  describe "reading" do
    it "reads named voices on one staff as one part, each with its role" do
      expect(parts(two_voices("Violin", "upper", "lower"))).to eq [[:violin, %w[upper lower]]]
    end

    it "reads unnamed voices on one staff as one part without roles" do
      expect(parts(two_voices("Violin", nil, nil))).to eq [[:violin, [nil, nil]]]
    end

    it "reads a named and an unnamed voice on one staff" do
      expect(parts(two_voices("Violin", "upper", nil))).to eq [[:violin, ["upper", nil]]]
    end

    it "keeps a staff's only voice named for the staff, with no instrument" do
      expect(parts(%(\\new Staff \\with { instrumentName = "Violin" } { \\new Voice = "upper" { c''1 } }))).to eq [[nil, ["Violin"]]]
    end

    it "reads no instrument from a name the catalog does not know" do
      expect(parts(two_voices("Melody", "upper", "lower"))).to eq [[nil, %w[upper lower]]]
    end

    it "keeps voices outside any staff as parts of their own" do
      expect(parts(%(<< \\new Voice = "a" { c''1 } \\new Voice = "b" { e'1 } >>)).length).to eq 2
    end

    it "reads a separate part per staff" do
      source = "<< #{two_voices("Violin", "upper", "lower")} #{two_voices("Viola", "upper", "lower")} >>"
      expect(parts(source).map(&:first)).to eq %i[violin viola]
    end

    it "places the dynamics beside the staff once" do
      flow = described_class.parse("<< #{two_voices("Violin", "upper", "lower")} \\new Dynamics { s1\\f } >>")
      expect(flow.parts.map { |part| part.dynamic_events.length }).to eq [1]
    end

    {
      "Clarinet in A" => :clarinet_in_a, "A Clarinet" => :clarinet_in_a, "Clarinet" => :clarinet
    }.each do |name, name_key|
      it "reads #{name.inspect} as the #{name_key}" do
        expect(parts(two_voices(name, "upper", "lower")).first.first).to eq name_key
      end
    end

    it "reads \"Clarinet\" with \\transposition a as the clarinet in A" do
      expect(parts(two_voices("Clarinet", "upper", "lower", opening: "\\transposition a")).first.first).to eq :clarinet_in_a
    end

    it "reads a later voice's \\transposition as choosing the variant" do
      source = %(\\new Staff \\with { instrumentName = "Clarinet" } << \\new Voice { c''1 } \\new Voice { \\transposition a e'1 } >>)
      expect(parts(source).first.first).to eq :clarinet_in_a
    end

    it "reads a staff's \\transposition as choosing the variant" do
      source = %(\\new Staff \\with { instrumentName = "Clarinet" } { \\transposition a << \\new Voice { c''1 } \\new Voice { e'1 } >> })
      expect(parts(source).first.first).to eq :clarinet_in_a
    end
  end

  describe "a round trip" do
    it "reads a two-voice part back as one part with its roles" do
      flow = two_voice_flow(:violin, ["upper", nil])
      expect(music(described_class.parse(described_class.render(flow)))).to eq music(flow)
    end

    it "reads a transposed two-voice part back as one part at concert pitch" do
      flow = two_voice_flow(:clarinet_in_a, %w[upper lower])
      reparsed = described_class.parse(described_class.render(written(flow), transposed: true))
      expect(music(reparsed)).to eq music(flow)
    end
  end
end
