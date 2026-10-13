import Foundation
import Testing
@testable import toolpouch

struct ApplicationLinksTests {
    @Test func absentLinksAreNotActions() {
        let links = ApplicationLinks(privacyPolicyURL: nil, supportURL: "not a URL")
        #expect(links.privacyPolicy == nil)
        #expect(links.support == nil)
    }

    @Test func acceptsOnlyHTTPSWithoutEmbeddedCredentials() {
        let links = ApplicationLinks(privacyPolicyURL: "https://ioxtec.com/policy", supportURL: "http://ioxtec.com/support")
        #expect(links.privacyPolicy?.host == "ioxtec.com")
        #expect(links.support == nil)
        #expect(ApplicationLinks(privacyPolicyURL: "https://user:secret@ioxtec.com", supportURL: nil).privacyPolicy == nil)
    }
}
