import XCTest
@testable import sec_osx_app

final class PasswordManagerTests: XCTestCase {

    var passwordManager: PasswordManager!
    let testService = "testService"
    let testAccount = "test@example.com"
    let testPassword = "Test@1234"
    let testNotes = "Test notes"

    override func setUp() {
        super.setUp()
        passwordManager = PasswordManager()
        // Clear any existing test data
        clearAllPasswords()
    }

    override func tearDown() {
        // Clean up after each test
        clearAllPasswords()
        super.tearDown()
    }

    private func clearAllPasswords() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        SecItemDelete(query as CFDictionary)
    }

    func testAddPassword() {
        // When
        passwordManager.addPassword(service: testService, account: testAccount, password: testPassword, notes: testNotes)

        // Then
        XCTAssertEqual(passwordManager.passwords.count, 1)
        let savedPassword = passwordManager.passwords.first
        XCTAssertEqual(savedPassword?.service, testService)
        XCTAssertEqual(savedPassword?.account, testAccount)
        XCTAssertEqual(savedPassword?.password, testPassword)
        XCTAssertEqual(savedPassword?.notes, testNotes)
    }

    func testDeletePassword() {
        // Given
        passwordManager.addPassword(service: testService, account: testAccount, password: testPassword)
        guard let passwordId = passwordManager.passwords.first?.id else {
            XCTFail("Failed to add test password")
            return
        }

        // When
        passwordManager.deletePassword(passwordId)

        // Then
        XCTAssertTrue(passwordManager.passwords.isEmpty)
    }

    func testPasswordUniqueness() {
        // When adding the same password twice
        passwordManager.addPassword(service: testService, account: testAccount, password: testPassword)
        passwordManager.addPassword(service: testService, account: testAccount, password: "NewPassword123!")

        // Then it should update the existing password
        XCTAssertEqual(passwordManager.passwords.count, 1)
        XCTAssertEqual(passwordManager.passwords.first?.password, "NewPassword123!")
    }

    func testPasswordStrengthValidation() {
        // Weak password (only lowercase)
        XCTAssertLessThan(passwordStrength("weak"), 0.25)

        // Medium password (lowercase + uppercase + numbers)
        let mediumStrength = passwordStrength("Medium123")
        XCTAssertGreaterThan(mediumStrength, 0.25)
        XCTAssertLessThan(mediumStrength, 0.5)

        // Strong password (lowercase + uppercase + numbers + special chars)
        let strongStrength = passwordStrength("Strong@123!")
        XCTAssertGreaterThan(strongStrength, 0.5)

        // Very strong password (long with all character types)
        let veryStrongStrength = passwordStrength("Very$tr0ngP@ssw0rd!123")
        XCTAssertGreaterThan(veryStrongStrength, 0.75)
    }

    func testPasswordGeneration() {
        // When
        let password = generateStrongPassword()

        // Then
        // Should be at least 12 characters long
        XCTAssertGreaterThanOrEqual(password.count, 12)

        // Should contain at least one of each character type
        let characterSet = CharacterSet(charactersIn: password)
        XCTAssertTrue(characterSet.intersection(.lowercaseLetters).isEmpty == false)
        XCTAssertTrue(characterSet.intersection(.uppercaseLetters).isEmpty == false)
        XCTAssertTrue(characterSet.intersection(.decimalDigits).isEmpty == false)

        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-={}[]|:;\"'<>,.?~`/\\")
        XCTAssertTrue(characterSet.intersection(specialCharacters).isEmpty == false)
    }

    // MARK: - Helper Methods

    private func passwordStrength(_ password: String) -> Double {
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

    private func generateStrongPassword() -> String {
        let length = 16
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
        remainingLength = length - 4

        // Fill the rest with random characters
        let allChars = uppercase + lowercase + numbers + special
        for _ in 0..<remainingLength {
            password.append(allChars.randomElement()!)
        }

        // Shuffle the password to avoid predictable patterns
        return String(password.shuffled())
    }
}
