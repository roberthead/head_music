# Respells a flow from its key numbers and compares each sounding pitch with
# the one written: each pitch of a chord once, a tied chain once, as one voice
# event holds it, and grace notes counted apart.
module SpellingEvaluation
  Miss = Data.define(:address, :written, :spelled, :rule) do
    def grace?
      address.include?("grace_notes")
    end
  end

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

  # As differences, but each miss with the rule that spelled it, read from
  # the speller rather than from a rebuilt flow.
  def misses(flow, key:, **finder_options)
    respelling = HeadMusic::Analysis::PitchSpeller::Respelling.new(flow, key: key, **finder_options)
    written = flow.to_h
    grace_count = respelling.addresses.count { |address| address.include?("grace_notes") }
    {
      count: respelling.addresses.length - grace_count,
      grace_count: grace_count,
      misses: respelling.addresses.zip(respelling.spelled_notes).filter_map do |address, spelled_note|
        before = written.dig(*address)
        after = spelled_note.pitch.to_s
        Miss.new(address, before, after, spelled_note.rule) unless before == after
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
