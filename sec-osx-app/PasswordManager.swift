//
//  PasswordManager.swift
//  sec-osx-app
//
//  Password Manager for securely storing and retrieving passwords
//

import Foundation
import Security

public class PasswordManager: ObservableObject {
    public static let shared = PasswordManager()
    @Published public var passwords: [PasswordItem] = []

    #if DEBUG
    init() {
        loadPasswords()
    }
    #else
    private init() {
        loadPasswords()
    }
    #endif

    public struct PasswordItem: Identifiable, Codable {
        public let id: UUID
        public var service: String
        public var account: String
        public var password: String
        public var notes: String
        public var lastUpdated: Date

        public init(service: String, account: String, password: String, notes: String = "") {
            self.id = UUID()
            self.service = service
            self.account = account
            self.password = password
            self.notes = notes
            self.lastUpdated = Date()
        }
    }

    public func addPassword(service: String, account: String, password: String, notes: String = "") {
        let newItem = PasswordItem(service: service, account: account, password: password, notes: notes)
        savePasswordToKeychain(item: newItem)
        loadPasswords()
    }

    private func savePasswordToKeychain(item: PasswordItem) {
        let passwordData = item.password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: item.service,
            kSecAttrAccount as String: item.account,
            kSecValueData as String: passwordData,
            kSecAttrComment as String: item.notes,
            kSecAttrModificationDate as String: item.lastUpdated
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to keychain: \(status)")
        }
    }

    private func loadPasswords() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        var loadedPasswords: [PasswordItem] = []

        if status == errSecSuccess, let items = result as? [[String: Any]] {
            for item in items {
                if let service = item[kSecAttrService as String] as? String,
                   let account = item[kSecAttrAccount as String] as? String,
                   let passwordData = item[kSecValueData as String] as? Data,
                   let password = String(data: passwordData, encoding: .utf8),
                   let notes = item[kSecAttrComment as String] as? String,
                   let lastUpdated = item[kSecAttrModificationDate as String] as? Date {

                    loadedPasswords.append(PasswordItem(
                        service: service,
                        account: account,
                        password: password,
                        notes: notes
                    ))
                }
            }
        }

        DispatchQueue.main.async {
            self.passwords = loadedPasswords
        }
    }

    public func deletePassword(_ id: UUID) {
        if let index = passwords.firstIndex(where: { $0.id == id }) {
            let item = passwords[index]
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: item.service,
                kSecAttrAccount as String: item.account
            ]
            SecItemDelete(query as CFDictionary)
            loadPasswords()
        }
    }
}
