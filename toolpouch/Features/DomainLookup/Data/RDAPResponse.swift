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

/// Small decoder scoped to the flexible vCard fragment returned by RDAP.
/// It intentionally stays local to this feature rather than becoming a
/// general-purpose transport type for a plugin system.
nonisolated enum JSONValue: Decodable, Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value."
            )
        }
    }

    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }
}
