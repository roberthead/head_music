# Respells a flow from its key numbers and compares each sounding pitch with
# the one written: each pitch of a chord once, a tied chain once, as one voice
# event holds it, and grace notes counted apart.
module SpellingEvaluation
  module_function

  def differences(flow, key:, **finder_options)
    addresses = HeadMusic::Analysis::NoteInput.for(flow).addresses
    written = flow.to_h
    respelled = HeadMusic::Analysis::PitchSpeller.respell(flow, key: key, **finder_options).to_h
    grace_count = addresses.count { |address| address.include?("grace_notes") }
    {
      count: addresses.length - grace_count,
      grace_count: grace_count,
      differences: addresses.filter_map do |address|
        before = written.dig(*address)
        after = respelled.dig(*address)
        "#{label(flow, address)} #{before} → #{after}" unless before == after
      end
    }
  end

  def label(flow, address)
    _, part_index, _, voice_index, _, event_index = address
    voice = flow.parts[part_index].voices[voice_index]
    role = voice.role || "voice #{part_index + 1}.#{voice_index + 1}"
    [voice.voice_events[event_index].position, role, ("grace" if address.include?("grace_notes"))].compact.join(" ")
  end
end
