#!/usr/bin/env ruby
# Deterministic merge of separately reviewed translation maps.
# Run with --check for validation only; no app files are changed in that mode.
require 'json'
require 'tempfile'

class UniqueTranslationMap < Hash
  def []=(key, value)
    raise "Duplicate JSON key: #{key}" if key?(key)
    super
  end
end

def format_arguments(text)
  text.scan(/%(?:(\d+)\$)?[-+#0 ']*\d*(?:\.\d+)?(hh|h|ll|l|z|t|j)?([@diuoxXfFeEgGaAcCsSp])/).each_with_index.map do |(position, length, type), index|
    [(position || index + 1).to_i, "#{length}#{type}"]
  end.sort
end

root = File.expand_path('..', __dir__)
path = File.join(root, 'toolpouch/Resources/Localizable.xcstrings')
catalog = JSON.parse(File.read(path), object_class: UniqueTranslationMap)
# The duplicate guard applies to input parsing, not intentional replacements.
catalog = JSON.parse(JSON.generate(catalog))
requirements = JSON.parse(File.read(File.join(root, 'toolpouch/Resources/LocalizationRequirements.json')))
keys = (catalog.fetch('strings').keys - ['Available on %@']).sort
languages = requirements.fetch('releaseLanguages') - [catalog.fetch('sourceLanguage'), 'pl']

languages.each do |language|
  translation_path = File.join(root, 'docs/localization', "#{language}.json")
  translations = JSON.parse(File.read(translation_path), object_class: UniqueTranslationMap)
  missing = keys - translations.keys
  extra = translations.keys - keys
  raise "#{language}: missing #{missing.inspect}; extra #{extra.inspect}" unless missing.empty? && extra.empty?
  translations.each do |key, value|
    raise "#{language}: invalid value for #{key.inspect}" unless value.is_a?(String) && (key.strip.empty? || !value.strip.empty?)
    raise "#{language}: format arguments differ for #{key.inspect}" unless format_arguments(key) == format_arguments(value)
    entry = catalog['strings'].fetch(key)
    entry['localizations'] ||= {}
    entry['localizations'][language] = { 'stringUnit' => { 'state' => 'translated', 'value' => value } }
  end
  puts "#{language}: validated #{translations.size} translations"
end

# Main-maintained grammatical variants and the platform accessibility sentence.
plural_forms = {
  'en' => { 'one' => '%lld tool', 'other' => '%lld tools' },
  'pl' => { 'one' => '%lld narzędzie', 'few' => '%lld narzędzia', 'many' => '%lld narzędzi', 'other' => '%lld narzędzia' },
  'de' => { 'one' => '%lld Werkzeug', 'other' => '%lld Werkzeuge' },
  'fr' => { 'one' => '%lld outil', 'other' => '%lld outils' },
  'es' => { 'one' => '%lld herramienta', 'other' => '%lld herramientas' },
  'it' => { 'one' => '%lld strumento', 'other' => '%lld strumenti' },
  'pt-BR' => { 'one' => '%lld ferramenta', 'other' => '%lld ferramentas' },
  'ja' => { 'other' => '%lld個のツール' },
  'ko' => { 'other' => '도구 %lld개' },
  'zh-Hans' => { 'other' => '%lld 个工具' },
  'zh-Hant' => { 'other' => '%lld 個工具' }
}
plural_forms.each do |language, forms|
  catalog['strings'].fetch('%lld tools')['localizations'][language] = {
    'variations' => { 'plural' => forms.transform_values { |value|
      { 'stringUnit' => { 'state' => 'translated', 'value' => value } }
    } }
  }
end
platform_labels = {
  'en' => 'Available on %@', 'pl' => 'Dostępne na: %@',
  'de' => 'Verfügbar auf %@', 'fr' => 'Disponible sur %@',
  'es' => 'Disponible en %@', 'it' => 'Disponibile su %@',
  'pt-BR' => 'Disponível em %@', 'ja' => '%@で利用できます',
  'ko' => '%@에서 사용 가능', 'zh-Hans' => '可在 %@ 上使用',
  'zh-Hant' => '可在 %@ 上使用'
}
catalog['strings']['Available on %@'] = {
  'localizations' => platform_labels.transform_values { |value|
    { 'stringUnit' => { 'state' => 'translated', 'value' => value } }
  }
}

unless ARGV.include?('--check')
  # This is only a mechanical merge; translators never edit the shared catalog.
  # Write next to the catalog and atomically replace it after every map passes.
  Tempfile.create(['localization-merge-', '.json'], File.dirname(path)) do |temporary|
    temporary.write(JSON.pretty_generate(catalog) + "\n")
    temporary.flush
    temporary.close
    File.rename(temporary.path, path)
  end
  puts 'Merged all required translation maps into the String Catalog.'
end
