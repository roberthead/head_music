# The projects the layout specs select from. Chairs are authored before the
# flows so that one player is the same player across movements.
module LayoutFixtures
  module_function

  # The flute plays in movements I and III; the violin plays in all three.
  def suite
    project = HeadMusic::Content::Project.new(name: "Suite")
    flute = project.add_player(name: "Flute")
    violin = project.add_player(name: "Violin")
    project.add_flow(movement("I", flute => %w[C5 D5 E5 F5], violin => %w[G4 A4 B4 C5]))
    project.add_flow(movement("II", violin => %w[A4 B4 C5 D5]))
    project.add_flow(movement("III", flute => %w[D5 E5 F5 G5], violin => %w[E4 F4 G4 A4]))
    project
  end

  # One tune, one chair: the shape every document this gem produced before
  # layouts existed, and so the shape a layout must not change.
  def single_flow_project
    project = HeadMusic::Content::Project.new(name: "Session Tunes")
    project.add_flow(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))
    project
  end

  # Three chairs whose instruments read in three different keys, so that one
  # transposed document has to carry three written keys.
  def trio
    project = HeadMusic::Content::Project.new(name: "Trio")
    chairs = {"Flute" => "flute", "Clarinet" => "clarinet", "Horn" => "french_horn"}
    players = chairs.keys.to_h { |name| [name, project.add_player(name: name)] }
    flow = HeadMusic::Content::Flow.new(name: "Trio", key_signature: "C major", meter: "4/4")
    chairs.each do |name, instrument|
      voice = flow.add_part(player: players[name], instrument: instrument).add_voice(role: instrument)
      %w[C4 D4].each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
    end
    project.add_flow(flow)
    project
  end

  # One B-flat clarinet, sounding C major: the smallest project in which
  # concert and written pitch differ.
  def clarinet_project(instrument: "clarinet", pitches: %w[C4 D4 E4 F4])
    project = HeadMusic::Content::Project.new(name: "Study")
    player = project.add_player(name: "Clarinet")
    flow = HeadMusic::Content::Flow.new(name: "Study", key_signature: "C major", meter: "4/4")
    voice = flow.add_part(player: player, instrument: instrument).add_voice(role: "clarinet")
    pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
    project.add_flow(flow)
    project
  end

  # Two woodwinds, a string, and a chair with no instrument at all, authored in
  # an order no ensemble would print them in.
  def mixed_ensemble
    project = HeadMusic::Content::Project.new(name: "Mixed")
    chairs = {"Violin" => "violin", "Clarinet" => "clarinet", "Singer" => nil, "Flute" => "flute"}
    flow = HeadMusic::Content::Flow.new(name: "Mixed", key_signature: "C major", meter: "4/4")
    chairs.each do |name, instrument|
      player = project.add_player(name: name)
      flow.add_part(player: player, instrument: instrument).add_voice(role: name.downcase).place("1:1", :whole, "C4")
    end
    project.add_flow(flow)
    project
  end

  def movement(name, lines)
    flow = HeadMusic::Content::Flow.new(name: name, key_signature: "C major", meter: "4/4")
    lines.each { |player, pitches| add_line(flow, player, pitches) }
    flow
  end

  def add_line(flow, player, pitches)
    instrument = player.name.downcase
    voice = flow.add_part(player: player, instrument: instrument).add_voice(role: instrument)
    pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
    voice
  end
end
