require 'yaml'

# Load the YAML files
instruments_file = '/Users/roberthead/github.com/roberthead/head_music/lib/head_music/instruments/instruments.yml'
families_file = '/Users/roberthead/github.com/roberthead/head_music/lib/head_music/instruments/instrument_families.yml'

instruments = YAML.load_file(instruments_file)
families = YAML.load_file(families_file)

puts "Checking for inconsistencies between instruments and their families...\n\n"

inconsistencies = []

instruments.each do |instrument_name, instrument_data|
  family_key = instrument_data['family_key']
  next unless family_key

  family_data = families[family_key]
  next unless family_data

  # Check orchestra_section_key consistency
  instrument_section = instrument_data['orchestra_section_key']
  family_section = family_data['orchestra_section_key']

  if instrument_section && family_section && instrument_section != family_section
    inconsistencies << {
      instrument: instrument_name,
      family: family_key,
      field: 'orchestra_section_key',
      instrument_value: instrument_section,
      family_value: family_section
    }
  end

  # Check classification_keys consistency
  instrument_classifications = instrument_data['classification_keys'] || []
  family_classifications = family_data['classification_keys'] || []

  # Check if instrument has classifications that conflict with family
  if !instrument_classifications.empty? && !family_classifications.empty?
    conflicts = instrument_classifications - family_classifications
    if !conflicts.empty?
      inconsistencies << {
        instrument: instrument_name,
        family: family_key,
        field: 'classification_keys',
        instrument_value: instrument_classifications,
        family_value: family_classifications,
        conflicts: conflicts
      }
    end
  end
end

if inconsistencies.empty?
  puts "No inconsistencies found!"
else
  puts "Found #{inconsistencies.length} inconsistencies:\n\n"

  inconsistencies.each_with_index do |issue, index|
    puts "#{index + 1}. #{issue[:instrument]} (family: #{issue[:family]})"
    puts "   Field: #{issue[:field]}"
    puts "   Instrument value: #{issue[:instrument_value]}"
    puts "   Family value: #{issue[:family_value]}"
    if issue[:conflicts]
      puts "   Conflicting classifications: #{issue[:conflicts]}"
    end
    puts ""
  end
end

# Also check for instruments with orchestra_section_key but no family
puts "\nInstruments with orchestra_section_key but no family_key:"
instruments.each do |instrument_name, instrument_data|
  if instrument_data['orchestra_section_key'] && !instrument_data['family_key']
    puts "- #{instrument_name}: #{instrument_data['orchestra_section_key']}"
  end
end

# Check for instruments with classification_keys but no family
puts "\nInstruments with classification_keys but no family_key:"
instruments.each do |instrument_name, instrument_data|
  if instrument_data['classification_keys'] && !instrument_data['family_key']
    puts "- #{instrument_name}: #{instrument_data['classification_keys']}"
  end
end
