require "spec_helper"

describe HeadMusic::MIDI::TickResolution do
  # Every onset and release, at its exact file time.
  def times_of(flow)
    timeline = HeadMusic::MIDI::PerformanceTimeline.new(flow)
    spans = timeline.spans.to_h { |span| [span.bar_number, span] }
    flow.voices.flat_map(&:voice_events).flat_map do |voice_event|
      HeadMusic::MIDI::BarPieces.of(voice_event, 0, voice_event.rhythmic_duration.fraction).flat_map do |piece|
        [spans[piece.bar_number].time_at(piece.from), spans[piece.bar_number].time_at(piece.to)]
      end
    end
  end

  def flow_of(values)
    HeadMusic::Content::Flow.new.tap do |flow|
      voice = flow.add_voice
      values.each { |value| voice.place(voice.next_position, value, "C4") }
    end
  end

  it "uses 480 for quarters" do
    expect(described_class.new(times_of(flow_of(%i[quarter quarter half])))).to have_attributes(division: 480, exact?: true)
  end

  it "uses 480 for triplets" do
    expect(described_class.new(times_of(TupletFixtures.triplets)).division).to eq 480
  end

  context "with TupletFixtures.septuplet" do
    let(:times) { times_of(TupletFixtures.septuplet) }
    let(:resolution) { described_class.new(times) }

    it "uses 3360, so each septuplet note is exact" do
      expect(resolution).to have_attributes(division: 3360, exact?: true)
    end

    it "lands every onset on a multiple of a seventh of the quarter" do
      onsets = times.each_slice(2).map(&:first).first(7)
      expect(onsets.map { |time| resolution.ticks(time) }).to eq((0..6).map { |index| index * 480 })
    end
  end

  context "with a mix of coprime ratios" do
    let(:times) do
      [3, 5, 7, 11, 13].flat_map do |count|
        (0..count).map { |index| Rational(index, count * 4) + count }
      end
    end
    let(:resolution) { described_class.new(times) }

    it "falls back to 960" do
      expect(resolution).to have_attributes(division: 960, exact?: false)
    end

    it "rounds each time on its own, so a long run never drifts" do
      run = (0..700).map { |index| Rational(index, 28) }
      fallback = described_class.new(run + times)
      expect(run.map { |time| (fallback.ticks(time) - time * 3840).abs }.max).to be <= Rational(1, 2)
    end

    it "keeps a note at least one tick long" do
      expect(resolution.note_ticks(Rational(1, 7_000), Rational(2, 7_000))).to eq [1, 2]
    end
  end

  it "keeps a staccatissimo dotted thirty-second exact" do
    sounding = Rational(3, 64) / 4
    expect(described_class.new([0, sounding])).to have_attributes(division: 960, exact?: true)
  end

  it "converts whole notes to ticks" do
    expect(described_class.new([0]).ticks(Rational(3, 4))).to eq 1440
  end
end
