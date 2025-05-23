#!/usr/bin/env ruby

# Test the translation loading functionality

# First test - German translation of solfege
result = system('bundle exec ruby -e "require \'head_music\'; puts HeadMusic::Rudiment::Solmization.get(\'Solfège\')&.name || \'nil\'"')
puts "German 'Solfège' test: #{result}"

# Second test - Italian translation
result = system('bundle exec ruby -e "require \'head_music\'; puts HeadMusic::Rudiment::Solmization.get(\'solfeggio\')&.name || \'nil\'"')
puts "Italian 'solfeggio' test: #{result}"

# Third test - Russian translation
result = system('bundle exec ruby -e "require \'head_music\'; puts HeadMusic::Rudiment::Solmization.get(\'сольфеджио\')&.name || \'nil\'"')
puts "Russian 'сольфеджио' test: #{result}"
