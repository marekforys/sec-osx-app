import XCTest
@testable import sec_osx_app

final class PasswordManagerMinimalTests: XCTestCase {
    var passwordManager: PasswordManager!
    let testService = "testService"
    let testAccount = "test@example.com"
    let testPassword = "Test@1234"
    let testNotes = "Test notes"

    // Test-specific constants
    let testService2 = "anotherService"
    let testAccount2 = "another@example.com"
    let testPassword2 = "Another@1234"
    let testNotes2 = "Another test note"

    override func setUp() {
        super.setUp()
        print("\n=== Setting up test environment ===")
        passwordManager = PasswordManager(useInMemoryStorage: true)
        print("Test environment ready\n")
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInitialState() {
        print("Testing initial state...")
        XCTAssertTrue(passwordManager.passwords.isEmpty, "Passwords array should be empty initially")
        print("Initial state test passed")
    }

    func testAddPassword() {
        // Given
        let expectation = self.expectation(description: "Password addition completed")
        print("Testing password addition...")

        // When
        passwordManager.addPassword(service: testService,
                                 account: testAccount,
                                 password: testPassword,
                                 notes: testNotes)

        // Wait for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                expectation.fulfill()
                return
            }

            print("Added password. Current passwords: \(self.passwordManager.passwords)")

            // Then
            XCTAssertEqual(self.passwordManager.passwords.count, 1, "Should have exactly one password after addition")

            guard let savedPassword = self.passwordManager.passwords.first else {
                XCTFail("No password was saved")
                expectation.fulfill()
                return
            }

            XCTAssertEqual(savedPassword.service, self.testService, "Service should match")
            XCTAssertEqual(savedPassword.account, self.testAccount, "Account should match")
            XCTAssertEqual(savedPassword.password, self.testPassword, "Password should match")
            XCTAssertEqual(savedPassword.notes, self.testNotes, "Notes should match")

            print("Password addition test passed")
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled, or timeout after 1 second
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testDeletePassword() {
        // Given
        let addExpectation = self.expectation(description: "Password addition completed")
        let deleteExpectation = self.expectation(description: "Password deletion completed")

        print("Testing password deletion...")

        // First, add a password
        passwordManager.addPassword(service: testService,
                                 account: testAccount,
                                 password: testPassword)

        // Wait for the add operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                addExpectation.fulfill()
                return
            }

            guard !self.passwordManager.passwords.isEmpty else {
                XCTFail("Failed to add test password")
                addExpectation.fulfill()
                return
            }

            let passwordId = self.passwordManager.passwords[0].id
            let initialCount = self.passwordManager.passwords.count

            print("Password added with ID: \(passwordId)")
            print("Current passwords before deletion: \(self.passwordManager.passwords)")

            // When
            self.passwordManager.deletePassword(passwordId)

            // Wait for the delete operation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else {
                    deleteExpectation.fulfill()
                    return
                }

                print("Password deleted. Current passwords: \(self.passwordManager.passwords)")

                // Then
                XCTAssertEqual(self.passwordManager.passwords.count, initialCount - 1, "Password count should decrease by 1")
                XCTAssertFalse(self.passwordManager.passwords.contains { $0.id == passwordId }, "Password with ID \(passwordId) should be deleted")

                print("Password deletion test passed")
                deleteExpectation.fulfill()
            }

            addExpectation.fulfill()
        }

        // Wait for both expectations to be fulfilled, or timeout after 2 seconds
        wait(for: [addExpectation, deleteExpectation], timeout: 2.0)
    }

    func testPasswordUniqueness() {
        // Given
        let firstAddExpectation = self.expectation(description: "First password addition completed")
        let secondAddExpectation = self.expectation(description: "Second password addition completed")

        print("Testing password uniqueness...")

        // First, add a password
        passwordManager.addPassword(service: testService,
                                 account: testAccount,
                                 password: testPassword)

        // Wait for the first add operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                firstAddExpectation.fulfill()
                return
            }

            let initialCount = self.passwordManager.passwords.count
            print("First password added. Current count: \(initialCount)")

            // When adding the same password again
            self.passwordManager.addPassword(service: self.testService,
                                          account: self.testAccount,
                                          password: "NewPassword123!")

            // Wait for the second add operation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else {
                    secondAddExpectation.fulfill()
                    return
                }

                print("Passwords after update: \(self.passwordManager.passwords)")

                // Then it should update the existing password
                XCTAssertEqual(self.passwordManager.passwords.count, initialCount, "Should not add duplicate password")

                guard let updatedPassword = self.passwordManager.passwords.first(where: {
                    $0.service == self.testService && $0.account == self.testAccount
                }) else {
                    XCTFail("Password not found after update")
                    secondAddExpectation.fulfill()
                    return
                }

                XCTAssertEqual(updatedPassword.password, "NewPassword123!", "Password should be updated")
                print("Password uniqueness test passed")
                secondAddExpectation.fulfill()
            }

            firstAddExpectation.fulfill()
        }

        // Wait for both expectations to be fulfilled, or timeout after 2 seconds
        wait(for: [firstAddExpectation, secondAddExpectation], timeout: 2.0)
    }
}
