# The tools and files outside the repository that some specs check against.
# A spec tagged `oracle: :name` is left out of the run unless its oracle is
# set up here; under ORACLES=1 (`rake oracles`) only tagged specs run, and
# those whose oracle is missing skip, saying how to set it up.
module Oracles
  Oracle = Data.define(:ready, :setup)

  ALL = {
    musescore: Oracle.new(
      -> { MuseScore.available? && (!ENV["MSCORE"].to_s.empty? || ENV["MUSESCORE_FIXTURES"] == "1") },
      "set MSCORE, or MUSESCORE_FIXTURES=1 with MuseScore 4 installed"
    ),
    kern_corpus: Oracle.new(-> { KernCorpus.directory }, "set KERN_CORPUS to a local clone of the Bach chorales"),
    mei_corpus: Oracle.new(-> { !folders("MEI_CORPUS").empty? }, "set MEI_CORPUS to local folders of MEI files"),
    musicxml_corpus: Oracle.new(-> { !folders("MUSICXML_CORPUS").empty? }, "set MUSICXML_CORPUS to local folders of MusicXML files"),
    mei_schema: Oracle.new(-> { ENV["MEI_SCHEMA"] }, "set MEI_SCHEMA to a local copy of mei-CMN.rng"),
    musicxml_xsd: Oracle.new(-> { ENV["MUSICXML_XSD"] }, "set MUSICXML_XSD to a local copy of musicxml.xsd"),
    verovio: Oracle.new(-> { which("verovio") }, "install verovio on the PATH"),
    abcm2ps: Oracle.new(-> { which("abcm2ps") }, "install abcm2ps on the PATH (brew install abcm2ps)")
  }.freeze

  module_function

  def ready?(name)
    ALL.fetch(name).ready.call ? true : false
  end

  def setup(name)
    ALL.fetch(name).setup
  end

  def folders(variable)
    ENV[variable].to_s.split(File::PATH_SEPARATOR).reject(&:empty?).map { |folder| File.expand_path(folder) }
  end

  def which(command)
    ENV["PATH"].to_s.split(File::PATH_SEPARATOR).map { |directory| File.join(directory, command) }.find { |path| File.executable?(path) }
  end
end
