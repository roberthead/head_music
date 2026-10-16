require "spec_helper"

describe HeadMusic::Notation::MEI do
  def bar_markings(flow)
    flow.bars.to_h { |bar| [bar.number, bar.to_h] }.reject { |_, marks| marks.empty? }
  end

  %w[marked_dal_segno_al_coda marked_da_capo_al_fine two_verses].each do |name|
    it "reads the bar markings of the #{name} golden back to its source's" do
      expect(bar_markings(described_class.parse(File.read(MEIFixtures.path(name))))).to eq bar_markings(MEIFixtures.source(name))
    end
  end

  NavigationFixtures.singleton_methods.sort.each do |name|
    it "reads the bar markings of NavigationFixtures.#{name} back from its render" do
      source = NavigationFixtures.public_send(name)
      expect(bar_markings(described_class.parse(source.to_mei))).to eq bar_markings(source)
    end
  end
end
