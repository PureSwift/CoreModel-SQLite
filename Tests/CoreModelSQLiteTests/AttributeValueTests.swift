//
//  AttributeValueTests.swift
//  CoreModel-SQLite
//
//  Unit tests for `AttributeValue(binding:type:)` decoding, exercising the error
//  paths (a stored value whose storage class doesn't match the declared attribute
//  type) and the `Binding` accessor helpers directly.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// A BLOB binding carrying the given bytes.
private func blobBinding(_ bytes: [UInt8] = [0x00]) -> Binding {
    Blob(bytes: bytes).binding
}

// MARK: - Successful decoding

@Test func decodeNullBinding() throws {
    // A nil binding decodes to `.null` regardless of the declared type.
    #expect(try AttributeValue(binding: nil, type: .int32) == .null)
    #expect(try AttributeValue(binding: nil, type: .string) == .null)
}

@Test func decodeDecimalFromNumericStorage() throws {
    // A decimal may be stored as TEXT, REAL or INTEGER; all decode back to `.decimal`.
    #expect(try AttributeValue(binding: .text("1.5"), type: .decimal) == .decimal(Decimal(string: "1.5")!))
    #expect(try AttributeValue(binding: .double(2.5), type: .decimal) == .decimal(Decimal(2.5)))
    #expect(try AttributeValue(binding: .integer(3), type: .decimal) == .decimal(Decimal(3)))
}

// MARK: - Decode error paths (storage class mismatch)

@Test func decodeTypeMismatchThrows() throws {
    // For each declared type, a binding of an incompatible storage class must throw.
    let blob = blobBinding()
    let cases: [(Binding, AttributeType)] = [
        (blob, .bool),
        (blob, .int16),
        (blob, .int32),
        (blob, .int64),
        (blob, .float),
        (blob, .double),
        (.integer(5), .string),   // textValue only accepts TEXT storage
        (.integer(5), .data),     // blobValue only accepts BLOB storage
        (blob, .date),
        (.integer(5), .uuid),     // not TEXT -> textValue nil
        (.integer(5), .url),      // not TEXT -> textValue nil
        (blob, .decimal)
    ]
    for (binding, type) in cases {
        #expect(throws: SQLiteDatabaseError.self) {
            try AttributeValue(binding: binding, type: type)
        }
    }
}

@Test func decodeIntegerOverflowThrows() throws {
    // A stored integer outside the fixed-width range can't be represented exactly.
    #expect(throws: SQLiteDatabaseError.self) {
        try AttributeValue(binding: .integer(99_999), type: .int16)
    }
    #expect(throws: SQLiteDatabaseError.self) {
        try AttributeValue(binding: .integer(Int64(Int32.max) + 1), type: .int32)
    }
}

@Test func decodeMalformedUUIDThrows() throws {
    #expect(throws: SQLiteDatabaseError.self) {
        try AttributeValue(binding: .text("not-a-uuid"), type: .uuid)
    }
}

// MARK: - Binding accessor helpers

@Test func bindingTextValueOnlyForText() {
    #expect(Binding.text("hi").textValue == "hi")
    #expect(Binding.integer(5).textValue == nil)
}

@Test func bindingBlobValueOnlyForBlob() {
    #expect(blobBinding([1, 2, 3]).blobValue == [1, 2, 3])
    #expect(Binding.integer(5).blobValue == nil)
}

@Test func bindingDecimalValueConversions() {
    #expect(Binding.text("4.25").decimalValue == Decimal(string: "4.25"))
    #expect(Binding.double(4.5).decimalValue == Decimal(4.5))
    #expect(Binding.integer(7).decimalValue == Decimal(7))
    #expect(blobBinding().decimalValue == nil)
}
