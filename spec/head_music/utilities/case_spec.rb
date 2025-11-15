require "spec_helper"

describe HeadMusic::Utilities::Case do
  describe ".to_snake_case" do
    it "converts PascalCase to snake_case" do
      expect(described_class.to_snake_case("HelloWorld")).to eq("hello_world")
    end

    it "converts camelCase to snake_case" do
      expect(described_class.to_snake_case("helloWorld")).to eq("hello_world")
    end

    it "converts kebab-case to snake_case" do
      expect(described_class.to_snake_case("hello-world")).to eq("hello_world")
    end

    it "leaves snake_case unchanged" do
      expect(described_class.to_snake_case("hello_world")).to eq("hello_world")
    end

    it "handles consecutive capitals" do
      expect(described_class.to_snake_case("HTTPSConnection")).to eq("https_connection")
    end

    it "handles namespace separators" do
      expect(described_class.to_snake_case("HeadMusic::Utilities")).to eq("head_music/utilities")
    end

    it "handles mixed case with numbers" do
      expect(described_class.to_snake_case("http2Protocol")).to eq("http2_protocol")
    end

    it "handles symbols" do
      expect(described_class.to_snake_case(:HelloWorld)).to eq("hello_world")
    end

    it "handles single words" do
      expect(described_class.to_snake_case("hello")).to eq("hello")
    end

    it "handles empty strings" do
      expect(described_class.to_snake_case("")).to eq("")
    end

    it "converts spaces to underscores" do
      expect(described_class.to_snake_case("hello world")).to eq("hello_world")
    end

    it "handles multiple spaces as single separator" do
      expect(described_class.to_snake_case("hello  world  test")).to eq("hello_world_test")
    end

    it "handles mixed spaces and other formats" do
      expect(described_class.to_snake_case("French Horn")).to eq("french_horn")
    end

    it "handles spaces with PascalCase" do
      expect(described_class.to_snake_case("C Major Scale")).to eq("c_major_scale")
    end

    it "squeezes consecutive underscores" do
      expect(described_class.to_snake_case("hello__world")).to eq("hello_world")
    end

    it "handles punctuation marks" do
      expect(described_class.to_snake_case("hello!world")).to eq("hello_world")
    end

    it "handles periods" do
      expect(described_class.to_snake_case("test.example")).to eq("test_example")
    end

    it "handles ampersands" do
      expect(described_class.to_snake_case("foo&bar")).to eq("foo_bar")
    end

    it "handles parentheses" do
      expect(described_class.to_snake_case("test(example)")).to eq("test_example")
    end

    it "handles multiple non-word characters" do
      expect(described_class.to_snake_case("hello!@#world")).to eq("hello_world")
    end

    it "strips leading underscores" do
      expect(described_class.to_snake_case("_hello_world")).to eq("hello_world")
    end

    it "strips trailing underscores" do
      expect(described_class.to_snake_case("hello_world_")).to eq("hello_world")
    end

    it "strips leading and trailing underscores from punctuation" do
      expect(described_class.to_snake_case("!hello@world#")).to eq("hello_world")
    end
  end

  describe ".to_kebab_case" do
    it "converts PascalCase to kebab-case" do
      expect(described_class.to_kebab_case("HelloWorld")).to eq("hello-world")
    end

    it "converts camelCase to kebab-case" do
      expect(described_class.to_kebab_case("helloWorld")).to eq("hello-world")
    end

    it "converts snake_case to kebab-case" do
      expect(described_class.to_kebab_case("hello_world")).to eq("hello-world")
    end

    it "leaves kebab-case unchanged" do
      expect(described_class.to_kebab_case("hello-world")).to eq("hello-world")
    end

    it "handles consecutive capitals" do
      expect(described_class.to_kebab_case("HTTPSConnection")).to eq("https-connection")
    end

    it "handles namespace separators" do
      expect(described_class.to_kebab_case("HeadMusic::Utilities")).to eq("head-music/utilities")
    end

    it "handles symbols" do
      expect(described_class.to_kebab_case(:HelloWorld)).to eq("hello-world")
    end

    it "handles single words" do
      expect(described_class.to_kebab_case("hello")).to eq("hello")
    end

    it "handles empty strings" do
      expect(described_class.to_kebab_case("")).to eq("")
    end
  end

  describe ".to_camel_case" do
    it "converts snake_case to camelCase" do
      expect(described_class.to_camel_case("hello_world")).to eq("helloWorld")
    end

    it "converts kebab-case to camelCase" do
      expect(described_class.to_camel_case("hello-world")).to eq("helloWorld")
    end

    it "converts PascalCase to camelCase" do
      expect(described_class.to_camel_case("HelloWorld")).to eq("helloWorld")
    end

    it "leaves camelCase unchanged" do
      expect(described_class.to_camel_case("helloWorld")).to eq("helloWorld")
    end

    it "handles consecutive capitals" do
      expect(described_class.to_camel_case("HTTPSConnection")).to eq("httpsConnection")
    end

    it "handles namespace separators" do
      expect(described_class.to_camel_case("HeadMusic::Utilities")).to eq("headMusic/utilities")
    end

    it "handles mixed formats" do
      expect(described_class.to_camel_case("hello-world_test")).to eq("helloWorldTest")
    end

    it "handles symbols" do
      expect(described_class.to_camel_case(:hello_world)).to eq("helloWorld")
    end

    it "handles single words" do
      expect(described_class.to_camel_case("hello")).to eq("hello")
    end

    it "handles empty strings" do
      expect(described_class.to_camel_case("")).to eq("")
    end

    it "handles multiple underscores" do
      expect(described_class.to_camel_case("hello__world")).to eq("helloWorld")
    end

    it "handles multiple hyphens" do
      expect(described_class.to_camel_case("hello--world")).to eq("helloWorld")
    end
  end
end
