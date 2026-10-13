#!/usr/bin/env ruby
# Read-only validation: ruby script/check_localizations.rb [language ...]
require 'json'

class UniqueLocalizationObject < Hash
  def []=(key, value)
    raise "Duplicate JSON key: #{key}" if key?(key)
    super
  end
end

def placeholders(text)
  text.scan(/%(?:(\d+)\$)?[-+#0 ']*\d*(?:\.\d+)?(hh|h|ll|l|z|t|j)?([@diuoxXfFeEgGaAcCsSp])/).each_with_index.map do |(position, length, type), index|
    [(position || index + 1).to_i, "#{length}#{type}"]
  end.sort
end

def translation_units(node)
  return [] unless node.is_a?(Hash)
  return [node['stringUnit']] if node.key?('stringUnit')
  node.values.flat_map { |value| translation_units(value) }
end

root = File.expand_path('..', __dir__)
catalog = JSON.parse(File.read(File.join(root, 'toolpouch/Resources/Localizable.xcstrings')), object_class: UniqueLocalizationObject)
requirements = JSON.parse(File.read(File.join(root, 'toolpouch/Resources/LocalizationRequirements.json')))
languages = ARGV.empty? ? requirements.fetch('releaseLanguages') : ARGV
failures = []
languages.each do |language|
  next if language == catalog['sourceLanguage']
  missing = 0
  catalog.fetch('strings').each do |key, entry|
    localization = entry.dig('localizations', language)
    units = translation_units(localization)
    unless !units.empty? && units.all? { |unit| unit['state'] == 'translated' && unit['value'].is_a?(String) }
      missing += 1
      next
    end
    units.each do |unit|
      failures << "#{language}: empty translation for #{key.inspect}" if !key.strip.empty? && unit['value'].strip.empty?
      failures << "#{language}: format arguments differ for #{key.inspect}" unless placeholders(key) == placeholders(unit['value'])
    end
  end
  puts "#{language}: #{catalog['strings'].size - missing}/#{catalog['strings'].size} translated"
  failures << "#{language}: #{missing} translations missing or unreviewed" if missing.positive?
end
failures.each { |failure| warn "BLOCKED: #{failure}" }
exit(failures.empty? ? 0 : 1)
