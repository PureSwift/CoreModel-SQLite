//
//  CustomFunction.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/16/26.
//

import Foundation
import CoreModel
import SQLite
#if canImport(Darwin)
import SQLite3
#elseif canImport(SQLiteSwiftCSQLite)
import SQLiteSwiftCSQLite
#elseif canImport(CSQLite)
import CSQLite
#else
import SQLite3
#endif

// Registers custom scalar functions by calling `sqlite3_create_function_v2` directly
// with `@convention(c)` function pointers, rather than SQLite.swift's `createFunction`.
// SQLite.swift registers the callback with a `@convention(block)` closure cast to a raw
// pointer, which is unreliable off Apple platforms (upstream
// https://github.com/stephencelis/SQLite.swift/issues/1071). A plain C function pointer
// plus a retained context pointer works identically on every platform.

/// The SQLite `SQLITE_TRANSIENT` sentinel destructor, telling SQLite to copy a result
/// value immediately (it is a macro in C, so it isn't imported).
private let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Retains a ``DatabaseFunction`` so it can be passed through SQLite as an opaque pointer
/// and recovered inside the C callback.
private final class FunctionBox {
    let function: DatabaseFunction
    init(_ function: DatabaseFunction) { self.function = function }
}

internal extension SQLite.Connection {

    /// Registers a `DatabaseFunction` with this connection via the SQLite C API.
    func register(function: DatabaseFunction) throws {
        let box = Unmanaged.passRetained(FunctionBox(function))
        let flags = SQLITE_UTF8 | (function.deterministic ? SQLITE_DETERMINISTIC : 0)
        let argumentCount = function.argumentCount.map { Int32($0) } ?? -1
        let code = sqlite3_create_function_v2(
            handle,
            function.name,
            argumentCount,
            flags,
            box.toOpaque(),
            { context, argc, argv in
                let function = Unmanaged<FunctionBox>.fromOpaque(sqlite3_user_data(context)).takeUnretainedValue().function
                var arguments = [AttributeValue?]()
                arguments.reserveCapacity(Int(argc))
                for index in 0..<Int(argc) {
                    arguments.append(argumentValue(argv?[index]))
                }
                setResult(context, function.evaluate(arguments))
            },
            nil, // xStep (scalar function, no aggregate)
            nil, // xFinal
            { pointer in
                // Balance `passRetained` when SQLite drops the function.
                guard let pointer else { return }
                Unmanaged<FunctionBox>.fromOpaque(pointer).release()
            }
        )
        guard code == SQLITE_OK else {
            box.release() // xDestroy isn't called when registration fails
            throw SQLiteDatabaseError.unableToCreateFunction(function.name, code)
        }
    }
}

/// Read a SQLite argument value into an ``AttributeValue``, inferring its shape from the
/// value's runtime storage class.
private func argumentValue(_ value: OpaquePointer?) -> AttributeValue {
    switch sqlite3_value_type(value) {
    case SQLITE_INTEGER:
        return .int64(sqlite3_value_int64(value))
    case SQLITE_FLOAT:
        return .double(sqlite3_value_double(value))
    case SQLITE_TEXT:
        guard let text = sqlite3_value_text(value) else { return .null }
        return .string(String(cString: text))
    case SQLITE_BLOB:
        guard let bytes = sqlite3_value_blob(value) else { return .data(Data()) }
        return .data(Data(bytes: bytes, count: Int(sqlite3_value_bytes(value))))
    default:
        return .null
    }
}

/// Set a function's result on the SQLite context from an ``AttributeValue``.
private func setResult(_ context: OpaquePointer?, _ value: AttributeValue?) {
    guard let value, let binding = value.binding else {
        sqlite3_result_null(context)
        return
    }
    switch binding {
    case let integer as Int64:
        sqlite3_result_int64(context, integer)
    case let double as Double:
        sqlite3_result_double(context, double)
    case let text as String:
        sqlite3_result_text(context, text, -1, transientDestructor)
    case let blob as Blob:
        sqlite3_result_blob(context, blob.bytes, Int32(blob.bytes.count), transientDestructor)
    default:
        sqlite3_result_null(context)
    }
}
