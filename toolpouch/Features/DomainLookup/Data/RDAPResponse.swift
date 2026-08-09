import Foundation

nonisolated struct RDAPDomainResponse: Decodable, Sendable {
    struct Event: Decodable, Sendable {
        let eventAction: String
        let eventDate: String
    }

    struct Nameserver: Decodable, Sendable {
        let ldhName: String?
        let unicodeName: String?
    }

    struct SecureDNS: Decodable, Sendable {
        let delegationSigned: Bool?
    }

    struct Message: Decodable, Sendable {
        let title: String?
        let description: [String]?
    }

    struct Entity: Decodable, Sendable {
        let handle: String?
        let roles: [String]?
        let vcardArray: JSONValue?

        var displayName: String? {
            vcardValue(named: "fn") ?? vcardValue(named: "org")
        }

        private func vcardValue(named propertyName: String) -> String? {
            guard case let .array(root) = vcardArray,
                  root.count > 1,
                  case let .array(properties) = root[1] else {
                return nil
            }

            for property in properties {
                guard case let .array(values) = property,
                      values.count > 3,
                      values[0].stringValue == propertyName else {
                    continue
                }

                if let value = values[3].stringValue {
                    return value
                }

                if case let .array(parts) = values[3] {
                    return parts.compactMap(\.stringValue).joined(separator: " ")
                }
            }

            return nil
        }
    }

    let ldhName: String?
    let unicodeName: String?
    let handle: String?
    let status: [String]?
    let entities: [Entity]?
    let events: [Event]?
    let nameservers: [Nameserver]?
    let secureDNS: SecureDNS?
    let notices: [Message]?
    let remarks: [Message]?
}
