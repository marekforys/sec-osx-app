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
    @Published public private(set) var passwords: [PasswordItem] = []

    private let keychainQueue = DispatchQueue(label: "com.sec-osx-app.passwordmanager.keychain", qos: .userInitiated)
    private let useInMemoryStorage: Bool
    private var inMemoryStorage: [PasswordItem] = []

    #if DEBUG
    public init(useInMemoryStorage: Bool = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil) {
        print("\n=== PasswordManager init ===")
        print("useInMemoryStorage: \(useInMemoryStorage)")
        print("Is this a test environment: \(ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)")
        self.useInMemoryStorage = useInMemoryStorage
        print("Calling loadPasswords()...")
        loadPasswords()
        print("PasswordManager init completed")
    }
    #else
    private init() {
        self.useInMemoryStorage = false
        loadPasswords()
    }
    #endif

    public struct PasswordItem: Identifiable, Codable, Equatable, CustomStringConvertible {
        public let id: UUID
        public var service: String
        public var account: String
        public var password: String
        public var notes: String
        public var lastUpdated: Date

        public var description: String {
            return """
            PasswordItem(
                id: \(id),
                service: "\(service)",
                account: "\(account)",
                password: "[REDACTED]",
                notes: "\(notes)",
                lastUpdated: \(lastUpdated)
            )
            """
        }

        public static func == (lhs: PasswordItem, rhs: PasswordItem) -> Bool {
            return lhs.service == rhs.service && lhs.account == rhs.account
        }

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
        print("\n=== addPassword called ===")
        print("Service: \(service)")
        print("Account: \(account)")
        print("Password length: \(password.count)")
        print("Notes: \(notes)")

        let newItem = PasswordItem(service: service, account: account, password: password, notes: notes)
        print("Created new PasswordItem")

        // Save to keychain or in-memory storage
        print("Saving to keychain...")
        keychainQueue.async { [weak self] in
            guard let self = self else {
                print("Error: self is nil in keychainQueue")
                return
            }

            print("Inside keychainQueue.async")
            self.savePasswordToKeychain(item: newItem)

            // Update the local passwords array on the main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    print("Error: self is nil in main.async")
                    return
                }

                print("Inside main.async")
                print("Current passwords before update: \(self.passwords)")

                if let index = self.passwords.firstIndex(where: { $0.service == service && $0.account == account }) {
                    // Update existing password
                    print("Updating existing password at index \(index)")
                    self.passwords[index] = newItem
                    print("Updated passwords: \(self.passwords)")
                } else {
                    // Add new password
                    print("Adding new password")
                    self.passwords.append(newItem)
                    print("Passwords after append: \(self.passwords)")
                }
            }
        }
    }

    private func savePasswordToKeychain(item: PasswordItem) {
        if useInMemoryStorage {
            // Use in-memory storage for tests
            if let index = inMemoryStorage.firstIndex(where: { $0.service == item.service && $0.account == item.account }) {
                inMemoryStorage[index] = item
            } else {
                inMemoryStorage.append(item)
            }
            DispatchQueue.main.async {
                self.passwords = self.inMemoryStorage
            }
            return
        }

        // Use actual keychain for production
        keychainQueue.sync {
            guard let passwordData = item.password.data(using: .utf8) else {
                print("❌ Error: Failed to convert password to data")
                return
            }

            // Prepare the attributes to save
            var attributes: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: item.service,
                kSecAttrAccount as String: item.account,
                kSecValueData as String: passwordData,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                kSecReturnData as String: true
            ]

            // Add optional fields if they have values
            if !item.notes.isEmpty {
                attributes[kSecAttrComment as String] = item.notes
            }

            // First try to update the existing item
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: item.service,
                kSecAttrAccount as String: item.account
            ]

            // Delete any existing item first to avoid update issues
            let deleteStatus = SecItemDelete(query as CFDictionary)
            if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
                print("Error deleting existing keychain item: \(deleteStatus)")
                if let errorMessage = SecCopyErrorMessageString(deleteStatus, nil) as String? {
                    print("Keychain error: \(errorMessage)")
                }
                return
            }

            // Add the new item
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                print("Error adding to keychain: \(addStatus)")
                if let errorMessage = SecCopyErrorMessageString(addStatus, nil) as String? {
                    print("Keychain error: \(errorMessage)")
                }
            }
        }
    }

    private func loadPasswords() {
        if useInMemoryStorage {
            // Use in-memory storage for tests
            DispatchQueue.main.async {
                self.passwords = self.inMemoryStorage
            }
            return
        }

        // Use actual keychain for production
        keychainQueue.sync {
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
                       let password = String(data: passwordData, encoding: .utf8) {

                        // Get optional fields with default values
                        let notes = item[kSecAttrComment as String] as? String ?? ""

                        // Create password item
                        let passwordItem = PasswordItem(
                            service: service,
                            account: account,
                            password: password,
                            notes: notes
                        )

                        loadedPasswords.append(passwordItem)
                    }
                }
            } else if status != errSecItemNotFound {
                print("Error loading passwords: \(status)")
                if let errorMessage = SecCopyErrorMessageString(status, nil) as String? {
                    print("Keychain error: \(errorMessage)")
                }
            }

            // Update the passwords array on the main thread
            DispatchQueue.main.async {
                self.passwords = loadedPasswords
            }
        }
    }

    public func deletePassword(_ id: UUID) {
        if useInMemoryStorage {
            // Use in-memory storage for tests
            inMemoryStorage.removeAll { $0.id == id }
            DispatchQueue.main.async {
                self.passwords = self.inMemoryStorage
            }
            return
        }

        // Use actual keychain for production
        keychainQueue.sync {
            guard let index = self.passwords.firstIndex(where: { $0.id == id }) else {
                print("Password with id \(id) not found")
                return
            }

            let item = self.passwords[index]

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: item.service,
                kSecAttrAccount as String: item.account
            ]

            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                print("Error deleting password from keychain: \(status)")
                if let errorMessage = SecCopyErrorMessageString(status, nil) as String? {
                    print("Keychain error: \(errorMessage)")
                }
                return
            }

            // Update the local passwords array on the main thread
            DispatchQueue.main.async {
                self.passwords.remove(at: index)
            }
        }
    }

    // MARK: - Password Strength & Generation

    public func checkPasswordStrength(_ password: String) -> Double {
        var strength: Double = 0

        // Length check
        if password.count >= 12 { strength += 0.3 }
        else if password.count >= 8 { strength += 0.2 }
        else if password.count >= 6 { strength += 0.1 }

        // Complexity checks
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let specialCharacters = "!@#$%^&*()_+-={}[]|:;\"'<>,.?~`/\\"
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: specialCharacters)) != nil

        if hasUppercase { strength += 0.15 }
        if hasLowercase { strength += 0.15 }
        if hasNumbers { strength += 0.15 }
        if hasSpecial { strength += 0.25 }

        return min(max(strength, 0), 1)
    }

    public func generateStrongPassword(length: Int = 16) -> String {
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let special = "!@#$%^&*()_+-=[]{}|;:,.<>?"

        var password = ""
        var remainingLength = length

        // Ensure at least one character from each set
        password.append(uppercase.randomElement()!)
        password.append(lowercase.randomElement()!)
        password.append(numbers.randomElement()!)
        password.append(special.randomElement()!)
        remainingLength = max(0, length - 4)  // Ensure we don't go negative

        // Fill the rest with random characters
        let allChars = uppercase + lowercase + numbers + special
        for _ in 0..<remainingLength {
            password.append(allChars.randomElement()!)
        }

        // Shuffle the password to avoid predictable patterns
        return String(password.shuffled())
    }
}
