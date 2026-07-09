//
//  NotificationType.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 7/23/25.
//

/// Parking Notification Type
public enum ParkingNotificationType: String, Codable, CaseIterable, Sendable {

    case email = "Email"

    case sms = "SMS"
}
