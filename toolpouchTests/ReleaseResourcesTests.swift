import Foundation
import Testing
@testable import toolpouch

struct ReleaseResourcesTests {
    @Test func polishToolCountUsesSingularAndPluralForms() throws {
        let path = try #require(Bundle.main.path(forResource: "pl", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let expected = [1: "1 narzędzie", 2: "2 narzędzia", 5: "5 narzędzi", 12: "12 narzędzi", 22: "22 narzędzia"]
        for (count, text) in expected {
            let translated = String(localized: "\(count) tools", bundle: bundle, locale: Locale(identifier: "pl"))
            #expect(translated == text)
        }
    }

    @Test func releasedLanguagesContainInterfaceAndPermissionResources() throws {
        let requirementsURL = try #require(Bundle.main.url(forResource: "LocalizationRequirements", withExtension: "json"))
        let requirements = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: requirementsURL)) as? [String: [String]])
        let languages = try #require(requirements["releaseLanguages"])
        for language in languages where language != "en" {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            for key in ["Settings", "Open in Window", "Device & System", "Press Esc to exit Color Picking"] {
                #expect(bundle.localizedString(forKey: key, value: nil, table: "Localizable") != key)
            }
            for key in ["NSLocationUsageDescription", "NSScreenCaptureUsageDescription"] {
                #expect(bundle.localizedString(forKey: key, value: nil, table: "InfoPlist") != key)
            }
            #expect(bundle.localizedString(forKey: "Actions for %@", value: nil, table: "Localizable").contains("%@"))
        }
    }

    @Test func privacyReasonsAreBundledAndDoNotInventAnUptimeReason() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let object = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let manifest = try #require(object as? [String: Any])
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        let entries = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let reasons = Dictionary(uniqueKeysWithValues: try entries.map { entry in
            (try #require(entry["NSPrivacyAccessedAPIType"] as? String),
             try #require(entry["NSPrivacyAccessedAPITypeReasons"] as? [String]))
        })
        #expect(reasons["NSPrivacyAccessedAPICategoryUserDefaults"] == ["CA92.1"])
        #expect(reasons["NSPrivacyAccessedAPICategoryDiskSpace"] == ["85F4.1"])
        #expect(reasons["NSPrivacyAccessedAPICategoryFileTimestamp"] == ["3B52.1", "C617.1"])
        #expect(reasons["NSPrivacyAccessedAPICategorySystemBootTime"] == nil)
    }

    @Test func polishResourcesResolveCommonRuntimeLabels() throws {
        let path = try #require(Bundle.main.path(forResource: "pl", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        for key in ["Settings", "Open in Window", "Copied", "Needs Access", "Saved archive: %@", "The connection timed out.", "Press Esc to exit Color Picking"] {
            #expect(bundle.localizedString(forKey: key, value: nil, table: "Localizable") != key)
        }
        #expect(bundle.localizedString(forKey: "Actions for %@", value: nil, table: "Localizable").contains("%@"))
    }
}
