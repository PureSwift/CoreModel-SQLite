//
//  List.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import Foundation
import CoreModel

/// Comma separated list.
public struct List<Element> {

    internal var elements: [Element]
}

// MARK: - String Decoding

public extension List {

    init?(string: String, map: (String) -> (Element?)) {
        guard string.isEmpty == false else {
            self = []
            return
        }
        let components = string.components(separatedBy: ",")
        var values = [Element]()
        values.reserveCapacity(components.count)
        for var rawValue in components {
            // remove whitespace prefix
            while rawValue.first == " " {
                rawValue.removeFirst()
            }
            guard let value = map(rawValue) else {
                return nil
            }
            values.append(value)
        }
        self.init(elements: values)
    }
}

// MARK: - Array

public extension Array {

    init(_ list: List<Self.Element>) {
        self = list.elements
    }
}

public extension List {

    init(_ array: [Element]) {
        self.init(elements: array)
    }
}

// MARK: - Equatable

extension List: Equatable where Element: Equatable {}

// MARK: - Hashable

extension List: Hashable where Element: Hashable {}

// MARK: - Sendable

extension List: Sendable where Element: Sendable {}

// MARK: - Encodable

extension List: Encodable where Element: Encodable {

    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

// MARK: - Decodable

extension List: Decodable where Element: Decodable {

    public init(from decoder: Decoder) throws {
        self.elements = try [Element](from: decoder)
    }
}

// MARK: - CustomStringConvertible

extension List: CustomStringConvertible {

    public var description: String {
        return elements.reduce("", { $0 + ($0.isEmpty ? "" : ",") + "\($1)" })
    }
}

// MARK: - ExpressibleByArrayLiteral

extension List: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Element...) {
        self.init(elements: elements)
    }
}

// MARK: - RawRepresentable

public extension List where Element: RawRepresentable, Element.RawValue == String {

    init?(rawValue: String) {
        self.init(string: rawValue, map: { .init(rawValue: $0) })
    }
}

extension List: RawRepresentable where Element: RawRepresentable, Element.RawValue == String {

    public var rawValue: String {
        description
    }
}

// MARK: - Sequence

extension List: Sequence {

    public func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }
}

// MARK: - CoreModel

extension List: AttributeEncodable {

    public var attributeValue: AttributeValue {
        .string(description)
    }
}

extension List: AttributeDecodable where Element: AttributeDecodable {

    public init?(attributeValue: AttributeValue) {
        guard let string = String(attributeValue: attributeValue) else {
            return nil
        }
        self.init(string: string, map: { .init(attributeValue: .string($0)) })
    }
}
