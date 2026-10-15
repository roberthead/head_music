require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads rehearsal marks, segno, coda, Fine, To Coda, D.C., and D.S. onto
  # the bars their directions are in.
  #
  # A <sound> that navigates decides what a direction is, since exporters
  # draw a coda sign for To Coda and word jumps freely; its words then only
  # name a jump's target. With no such <sound>, the signs and words decide.
  # Every part is read: for each bar the first rehearsal mark and jump win,
  # and a flag set by any part is set.
  class NavigationReader < MarkReader
    FINE = /\AFine\.?\z/i
    TO_CODA = /\ATo\s+Coda\z/i

    def initialize
      @marks = Hash.new { |marks, number| marks[number] = {} }
    end

    def direction(record)
      element = record.element
      sound = (element.name == "sound") ? element : XmlReading.first_child(element, "sound")
      signs = (element.name == "direction") ? signs_in(element) : []
      marks = @marks[record.bar_number]
      read_rehearsal_mark(signs, marks)
      found = sound_marks(sound, words_in(signs))
      found = sign_marks(signs) if found.empty?
      found.each { |field, value| marks[field] ||= value }
    end

    def apply(flow)
      first = flow.earliest_bar_number
      last = flow.latest_bar_number
      @marks.each do |number, marks|
        next unless number.between?(first, last)

        current = flow.bar(number)
        marks.each { |field, value| current.public_send(:"#{field}=", value) }
      end
    end

    private

    def signs_in(element)
      XmlReading.children(element, "direction-type").flat_map { |type| type.elements.to_a }
    end

    def words_in(signs)
      signs.filter_map { |sign| XmlReading.text(sign) if sign.name == "words" }
    end

    def read_rehearsal_mark(signs, marks)
      text = signs.filter_map { |sign| XmlReading.text(sign) if sign.name == "rehearsal" }.find { |mark| !mark.empty? }
      marks[:rehearsal_mark] ||= text if text
    end

    def sound_marks(sound, words)
      return [] unless sound

      attribute = ->(name) { XmlReading.attribute(sound, name) }
      target = words.filter_map { |text| HeadMusic::Content::Jump.get(text)&.to }.first
      [
        attribute["segno"] && [:segno, true],
        attribute["coda"] && [:coda, true],
        attribute["tocoda"] && [:to_coda, true],
        attribute["fine"] && [:fine, true],
        attribute["dacapo"] == "yes" && [:jump, HeadMusic::Content::Jump.new(:da_capo, to: target)],
        attribute["dalsegno"] && [:jump, HeadMusic::Content::Jump.new(:dal_segno, to: target)]
      ].select { |mark| mark }
    end

    def sign_marks(signs)
      signs.filter_map do |sign|
        case sign.name
        when "segno" then [:segno, true]
        when "coda" then [:coda, true]
        when "words" then word_mark(XmlReading.text(sign))
        end
      end
    end

    def word_mark(text)
      return [:fine, true] if FINE.match?(text)
      return [:to_coda, true] if TO_CODA.match?(text)

      jump = HeadMusic::Content::Jump.get(text)
      jump && [:jump, jump]
    end
  end
end
