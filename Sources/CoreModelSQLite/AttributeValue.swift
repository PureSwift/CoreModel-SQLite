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
    var binding: Binding? {
        switch self {
        case .null:
            return nil
        case let .string(value):
            return value
        case let .uuid(value):
            return value.uuidString
        case let .url(value):
            return value.absoluteString
        case let .data(value):
            return Blob(bytes: [UInt8](value))
        case let .date(value):
            return value.timeIntervalSince1970
        case let .bool(value):
            return Int64(value ? 1 : 0)
        case let .int16(value):
            return Int64(value)
        case let .int32(value):
            return Int64(value)
        case let .int64(value):
            return value
        case let .float(value):
            return Double(value)
        case let .double(value):
            return value
        case let .decimal(value):
            return value.description
        }
    }

    /// Decode from a SQLite binding value with no declared attribute type (e.g. a
    /// raw argument passed into a custom SQL function), inferring the value's shape
    /// from the binding's runtime type.
    init(binding: Binding?) {
        switch binding {
        case .none:
            self = .null
        case let value as Int64:
            self = .int64(value)
        case let value as Double:
            self = .double(value)
        case let value as String:
            self = .string(value)
        case let value as Blob:
            self = .data(Data(value.bytes))
        default:
            self = .null
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
            guard let value = binding as? String else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .string(value)
        case .data:
            guard let value = binding as? Blob else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .data(Data(value.bytes))
        case .date:
            guard let value = binding.doubleValue else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .date(Date(timeIntervalSince1970: value))
        case .uuid:
            guard let string = binding as? String, let value = UUID(uuidString: string) else {
                throw SQLiteDatabaseError.invalidBinding(binding, type)
            }
            self = .uuid(value)
        case .url:
            guard let string = binding as? String, let value = URL(string: string) else {
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

private extension Binding {

    var int64Value: Int64? {
        switch self {
        case let value as Int64:
            return value
        case let value as Double:
            return Int64(exactly: value)
        case let value as String:
            return Int64(value)
        default:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case let value as Double:
            return value
        case let value as Int64:
            return Double(value)
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    var decimalValue: Decimal? {
        switch self {
        case let value as String:
            return Decimal(string: value)
        case let value as Double:
            return Decimal(value)
        case let value as Int64:
            return Decimal(value)
        default:
            return nil
        }
    }
}
