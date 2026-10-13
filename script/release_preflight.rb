#!/usr/bin/env ruby
# Read-only release checks. Run: ruby script/release_preflight.rb [path/to/app.app]
require 'json'
require 'uri'
require 'open3'

root = File.expand_path('..', __dir__)
failures = []
links = JSON.parse(File.read(File.join(root, 'toolpouch/Resources/ApplicationLinks.json')))
%w[privacyPolicyURL supportURL].each do |key|
  begin
    url = URI.parse(links[key].to_s)
    valid = url.is_a?(URI::HTTPS) && url.host && !url.host.empty? && url.userinfo.nil?
  rescue URI::InvalidURIError
    valid = false
  end
  failures << "#{key}: missing valid HTTPS URL; publish and verify the page before shipping" unless valid
end

catalog = JSON.parse(File.read(File.join(root, 'toolpouch/Resources/Localizable.xcstrings')))
languages = catalog.fetch('strings').values.flat_map { |entry| (entry['localizations'] || {}).keys }.uniq
puts "Catalog languages: #{([catalog['sourceLanguage']] + languages).uniq.join(', ')}"
puts 'Additional promised languages and full UI localization still require review.'
_, localization_errors, localization_status = Open3.capture3('ruby', File.join(root, 'script/check_localizations.rb'))
failures << "Localization release gate failed: #{localization_errors.strip}" unless localization_status.success?
collector = File.read(File.join(root, 'toolpouch/Features/SystemStats/Data/SystemStatsCollector.swift'))
failures << 'System uptime API remains in the collector without a verified approved reason' if collector.include?('systemUptime')

if (app = ARGV.first)
  plist = File.join(File.expand_path(app), 'Contents/Info.plist')
  output, status = Open3.capture2('/usr/bin/plutil', '-convert', 'json', '-o', '-', plist)
  if status.success?
    info = JSON.parse(output)
    puts "App: #{info['CFBundleIdentifier']} #{info['CFBundleShortVersionString']} (#{info['CFBundleVersion']}); minimum macOS #{info['LSMinimumSystemVersion']}"
    build = info['DTXcodeBuild'].to_s
    # Release builds can also end in a letter (for example 27A266a).
    verified_release_builds = %w[27A266a]
    failures << "Xcode build #{build}: verify App Store acceptance of this toolchain" unless verified_release_builds.include?(build)
    failures << 'Privacy manifest not found in the app bundle' if Dir.glob(File.join(app, 'Contents/**/PrivacyInfo.xcprivacy')).empty?
    _, signing_error, signing_status = Open3.capture3('/usr/bin/codesign', '--verify', '--strict', app)
    failures << "Signature validation failed: #{signing_error.strip}" unless signing_status.success?
    _, signature, = Open3.capture3('/usr/bin/codesign', '-dv', app)
    failures << 'App is ad-hoc signed or has no team; this is not a distribution build' if signature.include?('Signature=adhoc') || signature.include?('TeamIdentifier=not set')
  else
    failures << 'Cannot read the supplied app bundle'
  end
else
  failures << 'No distribution app supplied: archive signature, SDK and manifest checks not performed'
end

puts 'Manual gates: sandbox file access, CloudKit Production, macOS 26 runtime, store metadata, paid agreement, privacy/export compliance, screenshots, UI QA.'
if failures.empty?
  puts 'Automated checks passed. This does not replace manual gates or App Review.'
else
  failures.each { |failure| warn "BLOCKED: #{failure}" }
  exit 1
end
