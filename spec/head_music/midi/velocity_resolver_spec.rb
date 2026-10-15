require "spec_helper"

describe HeadMusic::MIDI::VelocityResolver do
  subject(:resolver) { described_class.new(voice) }

  let(:voice) { flow.voices.first }

  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Loudness\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  def event_at(code, in_voice = voice)
    in_voice.voice_event_at(in_voice.flow.position(code))
  end

  def velocities(in_voice = voice)
    resolver = described_class.new(in_voice)
    in_voice.note_events.map { |voice_event| resolver.velocity(voice_event) }
  end

  describe "#level" do
    def parity_failures(flow)
      flow.voices.flat_map do |each_voice|
        resolver = described_class.new(each_voice)
        each_voice.voice_events.filter_map do |voice_event|
          swept = resolver.level(voice_event)
          answered = each_voice.dynamic_at(voice_event.position)
          [voice_event.position.to_s, swept, answered] unless swept == answered
        end
      end
    end

    fixtures = HairpinFixtures.all.map { |name| [HairpinFixtures, name] } +
      %i[marked_melody grand_staff_piano_with_dynamics].map { |name| [MarkingFixtures, name] }
    fixtures.each do |fixtures_module, name|
      context "with #{name}" do
        it "answers what Voice#dynamic_at answers at every event" do
          expect(parity_failures(fixtures_module.public_send(name))).to eq []
        end
      end
    end

    it "answers what Voice#dynamic_at answers in the piano part marks" do
      expect(parity_failures(MuseScoreFixtures.piano_part_marks)).to eq []
    end

    context "with a voice level and a part level at one position" do
      let(:flow) { abc("C D E F|") }

      it "ranks the voice's over the part's, as dynamic_at does" do
        voice.place_dynamic("1:2", :ff)
        voice.part.place_dynamic("1:2", :pp)
        expect(resolver.level(event_at("1:2"))).to eq voice.dynamic_at(flow.position("1:2"))
      end
    end

    context "with an fp note where a level is placed" do
      let(:flow) { abc("!ff!!fp!C D E F|") }

      it "ranks the level fp leaves over the placed one, as dynamic_at does" do
        expect(parity_failures(flow)).to eq []
      end
    end
  end

  describe "#velocity" do
    context "with no level written" do
      let(:flow) { abc("C D E F|") }

      it "sounds every note at mf" do
        expect(velocities).to eq [80, 80, 80, 80]
      end
    end

    context "with levels" do
      let(:flow) { abc("!ppp!C !pp!D !p!E !mp!F|!mf!G !f!A !ff!B !fff!c|") }

      it "sounds each note at its level's velocity" do
        expect(velocities).to eq [16, 32, 48, 64, 80, 96, 112, 127]
      end
    end

    context "with a part's level" do
      let(:flow) { MarkingFixtures.grand_staff_piano_with_dynamics }

      it "sounds the part's level in every voice, and a voice's own level over it" do
        expect([velocities(flow.voices.first), velocities(flow.voices.last)]).to eq [[48, 48, 80, 64], [48, 48, 96, 64]]
      end
    end

    context "with an fp note" do
      let(:flow) { abc("!mf!C !fp!D E F|") }

      it "strikes the fp note at f and the notes after it at p" do
        expect(velocities).to eq [80, 96, 48, 48]
      end
    end

    context "with note dynamics and articulations" do
      let(:flow) { abc("!p!!sf!C !sfz!D !rfz!E !accent!F|!marcato!G !sfz!!accent!A !sfz!!marcato!B c|") }

      it "adds their boosts together" do
        expect(velocities).to eq [72, 72, 64, 64, 72, 88, 96, 48]
      end
    end

    context "with boosts beyond the loudest velocity" do
      let(:flow) { abc("!fff!!sfz!!marcato!C|") }

      it "clamps to 127" do
        expect(velocities).to eq [127]
      end
    end

    context "with a crescendo to a placed level" do
      let(:flow) { abc("!p!!<(!C D E F|!<)!!f!G4|") }

      it "ramps by onset from the level at its start to the level at its end" do
        expect(velocities).to eq [48, 60, 72, 84, 96]
      end
    end

    context "with a crescendo and no level at its end" do
      let(:flow) { abc("!p!!<(!C D E F|!<)!G G G G|!pp!C4|") }

      it "ramps to one level beyond its start, which stays in force until the next level" do
        expect(velocities).to eq [48, 52, 56, 60, 64, 64, 64, 64, 32]
      end
    end

    context "with a diminuendo and no level at its end" do
      let(:flow) { abc("!f!!>(!C D E F|!>)!G4|") }

      it "ramps down one level" do
        expect(velocities).to eq [96, 92, 88, 84, 80]
      end
    end

    context "with a diminuendo from the softest level, and no level at its end" do
      let(:flow) { abc("!ppp!!>(!C D E F|!>)!G4|") }

      it "stays at the softest level" do
        expect(velocities).to eq [16, 16, 16, 16, 16]
      end
    end

    context "with a crescendo and no level before it" do
      let(:flow) { abc("!<(!C D E F|!<)!G4|") }

      it "ramps from mf" do
        expect(velocities).to eq [80, 84, 88, 92, 96]
      end
    end

    context "with a level placed inside a crescendo" do
      let(:flow) { HairpinFixtures.level_inside_hairpin }

      it "ends the ramp at the level, and ramps on from it" do
        expect(velocities).to eq [80, 80, 80, 112, 96]
      end
    end

    context "with a crescendo whose start falls under a held note" do
      let(:flow) { HairpinFixtures.hairpin_under_held_note }

      it "interpolates from the crescendo's start, not the note's" do
        expect(velocities).to eq [80, 92, 96]
      end
    end

    context "with touching hairpins" do
      let(:flow) { abc("!p!!<(!C D E F|!<)!!>(!G A B c|!>)!C4|") }

      it "starts the second from the level the first left in force" do
        expect(velocities).to eq [48, 52, 56, 60, 64, 60, 56, 52, 48]
      end
    end

    context "with a part's crescendo" do
      let(:flow) { MarkingFixtures.grand_staff_piano_with_dynamics }

      before { flow.parts.first.add_span(:crescendo, from: "1:1", to: "2:3") }

      it "ramps every voice of the part" do
        expect([velocities(flow.voices.first), velocities(flow.voices.last)]).to eq [[48, 80, 80, 64], [48, 80, 96, 64]]
      end
    end

    context "with a voice's hairpin inside its part's" do
      let(:flow) { HairpinFixtures.part_hairpin }

      it "follows the voice's own in that voice, and the part's elsewhere" do
        expect([velocities(flow.voices.first), velocities(flow.voices.last)]).to eq [[80, 91, 112, 104], [80, 91, 96, 88]]
      end
    end

    context "with a voice's hairpin over the same stretch as its part's" do
      let(:flow) { abc("!mf!C D E F|G4|") }

      before do
        voice.add_span(:diminuendo, from: "1:1", to: "2:1")
        voice.part.add_span(:crescendo, from: "1:1", to: "2:1")
      end

      it "follows the voice's, and leaves its level in force" do
        expect(velocities).to eq [80, 76, 72, 68, 64]
      end
    end

    context "with a part's hairpin inside a voice's" do
      let(:flow) { abc("!p!C D E F|G4|") }

      before do
        voice.add_span(:crescendo, from: "1:1", to: "2:1")
        voice.part.add_span(:diminuendo, from: "1:3", to: "2:1")
      end

      it "follows the innermost, and leaves its level in force" do
        expect(velocities).to eq [48, 52, 48, 40, 32]
      end
    end
  end

  describe "#grace_velocity" do
    let(:flow) { abc("!p!C !sfz!D E !fp!F|") }

    before do
      event_at("1:2").add_grace_note("C4", :eighth)
      event_at("1:4").add_grace_note("E4", :eighth, articulations: [:accent])
    end

    it "takes the main note's velocity without its note dynamic" do
      expect(resolver.grace_velocity(event_at("1:2"), event_at("1:2").grace_notes.first)).to eq 48
    end

    it "adds the grace note's own articulations, and not fp's attack" do
      expect(resolver.grace_velocity(event_at("1:4"), event_at("1:4").grace_notes.first)).to eq 64
    end

    context "with fp after a louder level" do
      let(:flow) { abc("!mf!C !fp!D E F|") }

      before { event_at("1:2").add_grace_note("C4", :eighth) }

      it "sounds at the level before the fp, not the one it leaves" do
        expect(resolver.grace_velocity(event_at("1:2"), event_at("1:2").grace_notes.first)).to eq 80
      end
    end
  end
end
