require "spec_helper"

describe HeadMusic::Notation::MEI::Markup do
  let(:element_class) { HeadMusic::Notation::MEI::Element }

  it "writes an empty element on one line, its id first" do
    element = element_class.new("note", "n1", {"pname" => "c", "oct" => 4})
    expect(described_class.lines(element)).to eq [%(<note xml:id="n1" pname="c" oct="4"/>)]
  end

  it "leaves out nil attributes" do
    expect(described_class.lines(element_class.new("rest", nil, {"dur" => "4", "dots" => nil}))).to eq [%(<rest dur="4"/>)]
  end

  it "writes text inside the element, escaped" do
    expect(described_class.lines(element_class.new("title", nil, {}, [], "Me & You"))).to eq ["<title>Me &amp; You</title>"]
  end

  it "escapes attribute values" do
    expect(described_class.lines(element_class.new("mdiv", nil, {"label" => %("Hi")}))).to eq [%(<mdiv label="&quot;Hi&quot;"/>)]
  end

  it "indents children one level deeper" do
    element = element_class.new("layer", nil, {}, [element_class.new("chord", nil, {}, [element_class.new("note")])])
    expect(described_class.lines(element, 1)).to eq ["  <layer>", "    <chord>", "      <note/>", "    </chord>", "  </layer>"]
  end
end
