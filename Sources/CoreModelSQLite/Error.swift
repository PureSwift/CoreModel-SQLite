//
//  Error.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/9/25.
//

import Foundation
import CoreModel
import SQLite

/// CoreModel SQLite Error
public enum SQLiteDatabaseError: Error {

    /// A value read from the database could not be decoded as the declared attribute type.
    case invalidBinding(Binding?, AttributeType)

    /// Unknown property for the entity.
    case invalidProperty(PropertyKey, EntityName)

    /// The predicate cannot be represented as SQL.
    case invalidPredicate(FetchRequest.Predicate)

    /// A custom function could not be registered with SQLite. Carries the SQLite result code.
    case unableToCreateFunction(String, Int32)
}
