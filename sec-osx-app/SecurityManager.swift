//
//  SecurityManager.swift
//  sec-osx-app
//
//  Security Manager for checking macOS security status
//

import Foundation
import Combine
import SwiftUI

class SecurityManager: ObservableObject {
    @Published var firewallStatus: FirewallStatus = .checking
    @Published var gatekeeperStatus: GatekeeperStatus = .checking
    @Published var fileVaultStatus: FileVaultStatus = .checking
    @Published var sipStatus: SIPStatus = .checking
    @Published var systemUpdates: SystemUpdateStatus = .checking
    @Published var isRefreshing: Bool = false

    init() {
        checkAllSecurityStatus()
    }

    func refresh() {
        isRefreshing = true
        checkAllSecurityStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isRefreshing = false
        }
    }

    private func checkAllSecurityStatus() {
        // Run checks on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.checkFirewallStatus()
            self.checkGatekeeperStatus()
            self.checkFileVaultStatus()
            self.checkSIPStatus()
            self.checkSystemUpdates()
        }
    }

    // MARK: - Firewall Status

    func checkFirewallStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/libexec/ApplicationFirewall/socketfilterfw")
        task.arguments = ["--getglobalstate"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("enabled") || output.contains("Firewall is ON") {
                DispatchQueue.main.async {
                    self.firewallStatus = .enabled
                }
            } else {
                DispatchQueue.main.async {
                    self.firewallStatus = .disabled
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.firewallStatus = .unknown
            }
        }
    }

    // MARK: - Gatekeeper Status

    func checkGatekeeperStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/spctl")
        task.arguments = ["--status"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("enabled") {
                DispatchQueue.main.async {
                    self.gatekeeperStatus = .enabled
                }
            } else {
                DispatchQueue.main.async {
                    self.gatekeeperStatus = .disabled
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.gatekeeperStatus = .unknown
            }
        }
    }

    // MARK: - FileVault Status

    func checkFileVaultStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/fdesetup")
        task.arguments = ["status"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("FileVault is On") {
                DispatchQueue.main.async {
                    self.fileVaultStatus = .enabled
                }
            } else if output.contains("FileVault is Off") {
                DispatchQueue.main.async {
                    self.fileVaultStatus = .disabled
                }
            } else {
                DispatchQueue.main.async {
                    self.fileVaultStatus = .unknown
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.fileVaultStatus = .unknown
            }
        }
    }

    // MARK: - System Integrity Protection (SIP) Status

    func checkSIPStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/csrutil")
        task.arguments = ["status"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("enabled") {
                DispatchQueue.main.async {
                    self.sipStatus = .enabled
                }
            } else if output.contains("disabled") {
                DispatchQueue.main.async {
                    self.sipStatus = .disabled
                }
            } else {
                DispatchQueue.main.async {
                    self.sipStatus = .unknown
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.sipStatus = .unknown
            }
        }
    }

    // MARK: - System Updates

    func checkSystemUpdates() {
        // Check for available software updates
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
        task.arguments = ["--list"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if output.contains("No new software available") || output.isEmpty {
                DispatchQueue.main.async {
                    self.systemUpdates = .upToDate
                }
            } else {
                DispatchQueue.main.async {
                    self.systemUpdates = .updatesAvailable
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.systemUpdates = .unknown
            }
        }
    }
}

// MARK: - Status Enums

enum FirewallStatus {
    case checking
    case enabled
    case disabled
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .gray
        case .enabled: return .green
        case .disabled: return .red
        case .unknown: return .orange
        }
    }
}

enum GatekeeperStatus {
    case checking
    case enabled
    case disabled
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .gray
        case .enabled: return .green
        case .disabled: return .red
        case .unknown: return .orange
        }
    }
}

enum FileVaultStatus {
    case checking
    case enabled
    case disabled
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .gray
        case .enabled: return .green
        case .disabled: return .red
        case .unknown: return .orange
        }
    }
}

enum SIPStatus {
    case checking
    case enabled
    case disabled
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .gray
        case .enabled: return .green
        case .disabled: return .red
        case .unknown: return .orange
        }
    }
}

enum SystemUpdateStatus {
    case checking
    case upToDate
    case updatesAvailable
    case unknown

    var displayName: String {
        switch self {
        case .checking: return "Checking..."
        case .upToDate: return "Up to Date"
        case .updatesAvailable: return "Updates Available"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .gray
        case .upToDate: return .green
        case .updatesAvailable: return .orange
        case .unknown: return .orange
        }
    }
}
