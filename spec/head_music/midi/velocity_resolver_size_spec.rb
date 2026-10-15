require "spec_helper"

# Velocities resolve in linear time: doubling the bars at most doubles the
# positions compared and the meters looked up, however the hairpins fall. It
# counts calls rather than timing them.
describe HeadMusic::MIDI::VelocityResolver do
  def counted
    {
      compare: [HeadMusic::Content::Position, :<=>],
      meter_at: [HeadMusic::Content::Flow::Timeline, :meter_at]
    }
  end

  # The calls each counted method takes to resolve every note's velocity in
  # a flow of so many bars.
  def measure(body)
    voice = HeadMusic::Notation::ABC.parse("X:1\nT:Size\nM:4/4\nL:1/8\nK:C\n#{body}\n").voices.first
    resolver = described_class.new(voice)
    counts = Hash.new(0)
    traces = counted.map do |name, (owner, method)|
      TracePoint.new(:call) { counts[name] += 1 }.tap { |trace| trace.enable(target: owner.instance_method(method)) }
    end
    voice.note_events.each { |voice_event| resolver.velocity(voice_event) }
    counts
  ensure
    traces&.each(&:disable)
  end

  bar = "CDEFGABc"
  {
    "one long hairpin" => ->(bars) { "!<(!" + ([bar] * (bars - 1)).join("|") + "|!<)!#{bar}|" },
    "many hairpins" => ->(bars) { (["!<(!#{bar}|!<)!#{bar}"] * (bars / 2)).join("|") + "|" },
    "one long hairpin cut at every bar" => ->(bars) { "!<(!" + (1...bars).map { |n| "!#{%w[p mp][n % 2]}!#{bar}" }.join("|") + "|!<)!#{bar}|" }
  }.each do |shape, body|
    it "resolves #{shape} in linear time" do
      small, large = [100, 200].map { |bars| measure(body.call(bars)) }
      expect(counted.keys.map { |name| large[name].fdiv(small[name]).round(2) }).to all(be <= 2.2)
    end
  end
end
