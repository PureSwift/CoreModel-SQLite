//
//  AttributeValue.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import Foundation
import CoreModel
import SQLite

internal extension AttributeValue {

    /// Convert to a SQLite binding value.
    ///
    /// `nil` represents a SQL `NULL`.
    var binding: Binding? {
        switch self {
        case .null:
            return nil
        case let .string(value):
            return .text(value)
        case let .uuid(value):
            return .text(value.uuidString)
        case let .url(value):
            return .text(value.absoluteString)
        case let .data(value):
            return Blob(bytes: [UInt8](value)).binding
        case let .date(value):
            return .double(value.timeIntervalSince1970)
        case let .bool(value):
            return .integer(value ? 1 : 0)
        case let .int16(value):
            return .integer(Int64(value))
        case let .int32(value):
            return .integer(Int64(value))
        case let .int64(value):
            return .integer(value)
        case let .float(value):
            return .double(Double(value))
        case let .double(value):
            return .double(value)
        case let .decimal(value):
            return .text(value.description)
        }
    }

    /// Decode from a SQLite binding value, interpreting it according to the declared attribute type.
    init(binding: Binding?, type: AttributeType) throws {
        guard let binding else {
            self = .null
            return
        }
        switch type {
        case .bool:
            guard let value = binding.int64Value else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .bool(value != 0)
        case .int16:
            guard let value = binding.int64Value, let integer = Int16(exactly: value) else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .int16(integer)
        case .int32:
            guard let value = binding.int64Value, let integer = Int32(exactly: value) else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .int32(integer)
        case .int64:
            guard let value = binding.int64Value else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .int64(value)
        case .float:
            guard let value = binding.doubleValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .float(Float(value))
        case .double:
            guard let value = binding.doubleValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .double(value)
        case .string:
            guard let value = binding.textValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .string(value)
        case .data:
            guard let value = binding.blobValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .data(Data(value))
        case .date:
            guard let value = binding.doubleValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .date(Date(timeIntervalSince1970: value))
        case .uuid:
            guard let string = binding.textValue, let value = UUID(uuidString: string) else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .uuid(value)
        case .url:
            guard let string = binding.textValue, let value = URL(string: string) else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .url(value)
        case .decimal:
            guard let value = binding.decimalValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .decimal(value)
        }
    }
}

internal extension Binding {

    /// The integer value, converting `REAL` and `TEXT` where possible.
    var int64Value: Int64? {
        integer
    }

    /// The floating-point value, converting `INTEGER` and `TEXT` where possible.
    var doubleValue: Double? {
        double
    }

    /// The stored text value, without converting numeric storage classes to text.
    var textValue: String? {
        guard case let .text(value) = self else {
            return nil
        }
        return value
    }

    /// The stored blob bytes, only for `BLOB` values.
    var blobValue: [UInt8]? {
        guard case .blob = self else {
            return nil
        }
        return bytes
    }

    /// The decimal value, parsed from `TEXT` or converted from a numeric storage class.
    var decimalValue: Decimal? {
        switch self {
        case let .text(value):
            return Decimal(string: value)
        case let .double(value):
            return Decimal(value)
        case let .integer(value):
            return Decimal(value)
        case .blob, .null:
            return nil
        }
    }
}
