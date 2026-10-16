require "spec_helper"

# TupletGenerator's flows of triplets and 6:4 sextuplets, with no grace
# notes and sometimes a pickup, read back by MIDI import as MIDIRoundTrip
# judges them. One voice, since two voices on one channel strike the same
# key while it sounds, which export cannot write back. A pickup a full bar
# long sounds like a first bar, so the bars are compared in order rather
# than by number. Seeds that cannot round-trip are excluded by name, each
# pinned as still differing. Run more with TUPLET_SEEDS=1..1000.
describe "HeadMusic::MIDI" do
  release_off_grid = "a lone triplet note before triplet rests puts only its release off the sixteenth grid its onsets fit"
  trailing_rests = "a last bar of rests is written only as the end of track's tick, which import does not read as music"
  excluded = {53 => release_off_grid, 82 => release_off_grid, 266 => release_off_grid, 87 => trailing_rests, 287 => trailing_rests, 954 => trailing_rests}

  def generated(seed)
    TupletGenerator.flow(seed, voices: 1, ratios: %w[3:2 6:4], graces: false, pickup: true)
  end

  def music(flow)
    MIDIRoundTrip.music(flow).tap { |music| music[:bars] = music[:bars].map { |bar| bar.drop(1) } }
  end

  def round_trip(written)
    bytes = HeadMusic::MIDI.render(written)
    flow = HeadMusic::MIDI.parse(bytes)
    {music: music(flow), events: MIDIRoundTrip.events(HeadMusic::MIDI.render(flow)), spelling: MIDIRoundTrip.spelling_differences(written, flow), written_events: MIDIRoundTrip.events(bytes)}
  end

  describe "TupletGenerator" do
    TupletGenerator::SEEDS.each do |seed|
      if excluded.key?(seed)
        it "leaves out seed #{seed}, since #{excluded.fetch(seed)}" do
          written = generated(seed)
          result = round_trip(written)
          expect([result[:music], result[:events]]).not_to eq [music(written), result[:written_events]]
        end
      else
        it "reads back seed #{seed} as written, and writes it again as read" do
          written = generated(seed)
          result = round_trip(written)
          expect(result.values_at(:music, :events, :spelling)).to eq [music(written), result[:written_events], []]
        end
      end
    end
  end
end
