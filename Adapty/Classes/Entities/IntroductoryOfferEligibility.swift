//
//  IntroductoryOfferEligibility.swift
//  Adapty
//
//  Created by Aleksei Valiano on 26.09.2022.
//

import Foundation

public enum IntroductoryOfferEligibility {
    case unknown
    case ineligible
    case eligible
}

extension IntroductoryOfferEligibility: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .ineligible: return "ineligible"
        case .eligible: return "eligible"
        }
    }
}

extension IntroductoryOfferEligibility: Equatable, Sendable {}

extension IntroductoryOfferEligibility: Codable {
    enum CodingValues: String {
        case unknown
        case ineligible
        case eligible
    }

    public init(from decoder: Decoder) throws {
        let value = CodingValues(rawValue: try decoder.singleValueContainer().decode(String.self))
        switch value {
        case .unknown: self = .unknown
        case .ineligible: self = .ineligible
        case .eligible: self = .eligible
        default: self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        let value: CodingValues
        switch self {
        case .unknown: value = .unknown
        case .ineligible: value = .ineligible
        case .eligible: value = .eligible
        }
        var container = encoder.singleValueContainer()
        try container.encode(value.rawValue)
    }
}