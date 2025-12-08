//
//  ContentView.swift
//  sec-osx-app
//
//  Main Content View
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var securityManager: SecurityManager

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            SecurityDashboardView()
                .environmentObject(securityManager)
        }
    }
}

struct SidebarView: View {
    var body: some View {
        List {
            Label("Security Dashboard", systemImage: "shield.checkered")
            Label("Firewall", systemImage: "network.badge.shield.half.filled")
            Label("Gatekeeper", systemImage: "lock.shield")
            Label("FileVault", systemImage: "lock.rotation")
            Label("System Integrity", systemImage: "checkmark.shield")
            Label("System Updates", systemImage: "arrow.down.circle")
        }
        .navigationTitle("Security")
    }
}

struct SecurityDashboardView: View {
    @EnvironmentObject var securityManager: SecurityManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Overview")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Monitor your macOS security status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        securityManager.refresh()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(securityManager.isRefreshing)
                }
                .padding(.horizontal)
                .padding(.top)

                // Security Status Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    SecurityStatusCard(
                        title: "Firewall",
                        description: "Network firewall protection",
                        status: securityManager.firewallStatus,
                        icon: "network.badge.shield.half.filled"
                    )

                    SecurityStatusCard(
                        title: "Gatekeeper",
                        description: "App security verification",
                        status: securityManager.gatekeeperStatus,
                        icon: "lock.shield"
                    )

                    SecurityStatusCard(
                        title: "FileVault",
                        description: "Disk encryption",
                        status: securityManager.fileVaultStatus,
                        icon: "lock.rotation"
                    )

                    SecurityStatusCard(
                        title: "System Integrity Protection",
                        description: "SIP status",
                        status: securityManager.sipStatus,
                        icon: "checkmark.shield"
                    )

                    SecurityStatusCard(
                        title: "System Updates",
                        description: "Software update status",
                        status: securityManager.systemUpdates,
                        icon: "arrow.down.circle"
                    )
                }
                .padding(.horizontal)

                // Security Recommendations
                SecurityRecommendationsView()
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SecurityStatusCard: View {
    let title: String
    let description: String
    let status: Any
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                Spacer()
                StatusBadge(status: status)
            }

            Text(title)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var statusColor: Color {
        if let firewallStatus = status as? FirewallStatus {
            return firewallStatus.color
        } else if let gatekeeperStatus = status as? GatekeeperStatus {
            return gatekeeperStatus.color
        } else if let fileVaultStatus = status as? FileVaultStatus {
            return fileVaultStatus.color
        } else if let sipStatus = status as? SIPStatus {
            return sipStatus.color
        } else if let updateStatus = status as? SystemUpdateStatus {
            return updateStatus.color
        }
        return .gray
    }
}

struct StatusBadge: View {
    let status: Any

    var body: some View {
        Text(statusDisplayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }

    private var statusDisplayName: String {
        if let firewallStatus = status as? FirewallStatus {
            return firewallStatus.displayName
        } else if let gatekeeperStatus = status as? GatekeeperStatus {
            return gatekeeperStatus.displayName
        } else if let fileVaultStatus = status as? FileVaultStatus {
            return fileVaultStatus.displayName
        } else if let sipStatus = status as? SIPStatus {
            return sipStatus.displayName
        } else if let updateStatus = status as? SystemUpdateStatus {
            return updateStatus.displayName
        }
        return "Unknown"
    }

    private var statusColor: Color {
        if let firewallStatus = status as? FirewallStatus {
            return firewallStatus.color
        } else if let gatekeeperStatus = status as? GatekeeperStatus {
            return gatekeeperStatus.color
        } else if let fileVaultStatus = status as? FileVaultStatus {
            return fileVaultStatus.color
        } else if let sipStatus = status as? SIPStatus {
            return sipStatus.color
        } else if let updateStatus = status as? SystemUpdateStatus {
            return updateStatus.color
        }
        return .gray
    }
}

struct SecurityRecommendationsView: View {
    @EnvironmentObject var securityManager: SecurityManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Recommendations")
                .font(.headline)
                .padding(.bottom, 4)

            if securityManager.firewallStatus == .disabled {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    message: "Enable Firewall to protect your Mac from network attacks",
                    color: .orange
                )
            }

            if securityManager.gatekeeperStatus == .disabled {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    message: "Enable Gatekeeper to verify downloaded applications",
                    color: .orange
                )
            }

            if securityManager.fileVaultStatus == .disabled {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    message: "Enable FileVault to encrypt your disk and protect your data",
                    color: .orange
                )
            }

            if securityManager.sipStatus == .disabled {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    message: "System Integrity Protection should be enabled for security",
                    color: .red
                )
            }

            if securityManager.systemUpdates == .updatesAvailable {
                RecommendationRow(
                    icon: "arrow.down.circle.fill",
                    message: "System updates are available. Install them to keep your Mac secure",
                    color: .blue
                )
            }

            if allSecurityEnabled {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    message: "All security features are properly configured",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var allSecurityEnabled: Bool {
        securityManager.firewallStatus == .enabled &&
        securityManager.gatekeeperStatus == .enabled &&
        securityManager.fileVaultStatus == .enabled &&
        securityManager.sipStatus == .enabled &&
        securityManager.systemUpdates == .upToDate
    }
}

struct RecommendationRow: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SecurityManager())
}

