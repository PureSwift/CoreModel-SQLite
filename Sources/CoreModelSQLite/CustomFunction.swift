//
//  CustomFunction.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/16/26.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import CoreModel
import SQLite

internal extension SQLite.Connection {

    /// Registers a `DatabaseFunction` as a custom SQL scalar function.
    func register(function: DatabaseFunction) throws {
        let evaluate = function.evaluate
        try createFunction(
            function.name,
            argumentCount: function.argumentCount.map { Int32($0) },
            deterministic: function.deterministic
        ) { arguments in
            let values: [AttributeValue?] = arguments.map { AttributeValue(functionArgument: $0) }
            guard let result = evaluate(values), let binding = result.binding else {
                return .null
            }
            return binding
        }
    }
}

private extension AttributeValue {

    /// Read a SQL function argument into an ``AttributeValue``, inferring its shape from
    /// the value's storage class.
    init(functionArgument binding: Binding) {
        switch binding {
        case let .integer(value):
            self = .int64(value)
        case let .double(value):
            self = .double(value)
        case let .text(value):
            self = .string(value)
        case .blob:
            self = .data(Data(binding.bytes ?? []))
        case .null:
            self = .null
        }
    }
}
