//based on BasicCodingKey.swift from vapor/vapor
// https://github.com/vapor/vapor/blob/main/Sources/Vapor/Utilities/BasicCodingKey.swift
import Foundation
/// Capable of being represented by a `CodingKey`.
public protocol CodingKeyRepresentable {
    /// Converts this type to a `CodingKey`.
    var codingKey: CodingKey { get }
}

extension String: CodingKeyRepresentable {
    /// See `CodingKeyRepresentable`
    public var codingKey: CodingKey {
        return BasicCodingKey.key(self)
    }
}

extension Int: CodingKeyRepresentable {
    /// See `CodingKeyRepresentable`
    public var codingKey: CodingKey {
        return BasicCodingKey.index(self)
    }
}

extension Array where Element == CodingKey {
    public var dotPath: String {
        return map { $0.stringValue }.joined(separator: ".")
    }
}

/// A basic `CodingKey` implementation.
public enum BasicCodingKey: CodingKey {
    case key(String)
    case index(Int)
    
    /// See `CodingKey`.
    public var stringValue: String {
        switch self {
        case .index(let index): return index.description
        case .key(let key): return key
        }
    }
    
    /// See `CodingKey`.
    public var intValue: Int? {
        switch self {
        case .index(let index): return index
        case .key(let key): return Int(key)
        }
    }
    
    /// See `CodingKey`.
    public init?(stringValue: String) {
        self = .key(stringValue)
    }
    
    /// See `CodingKey`.
    public init?(intValue: Int) {
        self = .index(intValue)
    }

    public init(_ codingKey: CodingKey) {
        if let intValue = codingKey.intValue {
            self = .index(intValue)
        } else {
            self = .key(codingKey.stringValue)
        }
    }

    public init(_ codingKeyRepresentable: CodingKeyRepresentable) {
        self.init(codingKeyRepresentable.codingKey)
    }
}

extension BasicCodingKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .index(let index):
            return index.description
        case .key(let key):
            return key.description
        }
    }
}

extension BasicCodingKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .index(let index):
            return index.description
        case .key(let key):
            return key.debugDescription
        }
    }
}
