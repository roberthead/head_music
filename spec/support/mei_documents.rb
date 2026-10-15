# Builds MEI documents from measure snippets, for reader specs that need what
# the writer never emits: per-staff layers, @staff on notes, child <accid>,
# editorial markup, attribute-form clefs, and malformed input.
#
# Each item is a measure's inner XML, wrapped as <measure n> and numbered
# from 1, or an element written whole where it starts with one of WHOLE,
# such as a <measure> with attributes of its own or a <scoreDef> between
# measures.
module MEIDocuments
  WHOLE = %w[<measure <scoreDef <staffDef <section <ending <app <choice <pb <sb <expansion].freeze

  def mei_document(*items, score_def: mei_score_def, head: mei_head, mdiv: %(<mdiv>), music_label: nil)
    label = music_label ? %( label="#{music_label}") : ""
    [
      %(<?xml version="1.0" encoding="UTF-8"?>),
      %(<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.1">),
      head,
      %(<music#{label}><body>#{mdiv}<score>),
      score_def,
      "<section>",
      *mei_items(items),
      "</section></score></mdiv></body></music></mei>"
    ].join("\n") + "\n"
  end

  def mei_items(items)
    number = 0
    items.map do |item|
      next item if WHOLE.any? { |start| item.lstrip.start_with?(start) }

      number += 1
      %(<measure n="#{number}">#{item}</measure>)
    end
  end

  def mei_head(title: "Test")
    %(<meiHead><fileDesc><titleStmt><title>#{title}</title></titleStmt><pubStmt/></fileDesc></meiHead>)
  end

  # A <scoreDef> of one staff per clef, each its own part.
  def mei_score_def(keysig: "0", meter: [4, 4], clefs: [%w[G 2]], extra: "", staff_grp: nil)
    count, unit = meter
    meter_attributes = meter ? %( meter.count="#{count}" meter.unit="#{unit}") : ""
    key = keysig ? %( keysig="#{keysig}") : ""
    group = staff_grp || "<staffGrp>#{clefs.each_with_index.map { |clef, index| mei_staff_def(index + 1, clef: clef) }.join}</staffGrp>"
    %(<scoreDef#{key}#{meter_attributes}#{extra}>#{group}</scoreDef>)
  end

  def mei_staff_def(number, clef: %w[G 2], inside: "", attributes: "")
    clef_xml = clef ? %(<clef shape="#{clef[0]}" line="#{clef[1]}"/>) : ""
    %(<staffDef n="#{number}" lines="5"#{attributes}>#{inside}#{clef_xml}</staffDef>)
  end

  # A staff of layers, each [number, content], or one layer's content.
  def mei_staff(number, *layers)
    layers = [[1, layers.first]] if layers.one? && layers.first.is_a?(String)
    %(<staff n="#{number}">#{layers.map { |layer, content| %(<layer n="#{layer}">#{content}</layer>) }.join}</staff>)
  end

  # A pitch such as "C4", "F#5", or "Bb3", written with its accidental shown,
  # or with +accid: nil+ to leave it unwritten.
  def mei_note(pitch, dur = "4", accid: :written, **attributes)
    letter, sign, octave = pitch.match(/\A([A-G])([#b]*)(-?\d)\z/).captures
    written = (accid == :written) ? {"#" => "s", "##" => "x", "b" => "f", "bb" => "ff"}[sign] : accid
    all = {pname: letter.downcase, oct: octave, dur: dur, accid: written}.merge(attributes).compact
    "<note #{all.map { |name, value| %(#{name.to_s.tr("_", ".")}="#{value}") }.join(" ")}/>"
  end

  def mei_rest(dur = "4", **attributes)
    all = {dur: dur}.merge(attributes).compact
    "<rest #{all.map { |name, value| %(#{name.to_s.tr("_", ".")}="#{value}") }.join(" ")}/>"
  end

  # That every voice satisfies Voice::Continuity and ends on a barline or
  # where the music ends. A voice may start and end in any bar, as a tacet
  # voice does.
  def expect_mei_music_whole(flow)
    voices = flow.voices.reject { |voice| voice.voice_events.empty? }
    expect(voices.map(&:first_gap)).to all(be_nil)
    ends = voices.map { |voice| voice.last_voice_event.next_position }
    expect(ends.reject { |position| position == ends.max || position.to_a.drop(1) == [1, 0, 0] }).to be_empty
  end
end

RSpec.configure { |config| config.include MEIDocuments }
