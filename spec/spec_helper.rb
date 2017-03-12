$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec/its'
require 'simplecov'
require 'head_music'

include HeadMusic

if ENV['CIRCLE_ARTIFACTS']
  dir = File.join(ENV['CIRCLE_ARTIFACTS'], 'coverage')
  SimpleCov.coverage_dir(dir)
end
SimpleCov.start

class HeadMusic::Style::Annotation
  def marks_count
    marks_array.length
  end

  def first_mark_code
    first_mark.code if first_mark
  end

  def first_mark
    marks_array.first
  end

  def marks_array
    [marks].flatten.compact
  end
end
