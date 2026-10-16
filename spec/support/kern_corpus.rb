# A local clone of https://github.com/craigsapp/bach-370-chorales, named by
# KERN_CORPUS. The corpus is CC BY-NC-SA 4.0, so none of it is committed here.
#
# Four chorales hold a bar the model cannot: two a short bar in the middle
# of the piece, one a 3/4 bar in 4/4 with a meter change inside the merged
# bar, and one an eight-beat bar.
module KernCorpus
  UNREADABLE = {
    "chor011.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError,
    "chor130.krn" => HeadMusic::Notation::Kern::ParseError,
    "chor197.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError,
    "chor280.krn" => HeadMusic::Notation::Kern::UnsupportedFeatureError
  }.freeze

  module_function

  def directory
    ENV["KERN_CORPUS"]
  end

  def paths
    directory ? Dir[File.join(directory, "kern", "*.krn")].sort : []
  end

  def readable_paths
    paths.reject { |path| UNREADABLE.key?(File.basename(path)) }
  end
end
