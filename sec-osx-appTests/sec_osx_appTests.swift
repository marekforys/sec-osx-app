//
//  sec_osx_appTests.swift
//  sec-osx-appTests
//
//  Created on macOS
//

import XCTest
@testable import sec_osx_app

final class sec_osx_appTests: XCTestCase {

    var securityManager: SecurityManager!

    override func setUp() {
        super.setUp()
        securityManager = SecurityManager()
    }

    override func tearDown() {
        securityManager = nil
        super.tearDown()
    }

    func testSecurityManagerInitialization() {
        XCTAssertNotNil(securityManager, "SecurityManager should be initialized")
    }

    func testFirewallStatusEnum() {
        let enabled = FirewallStatus.enabled
        XCTAssertEqual(enabled.displayName, "Enabled")
        XCTAssertEqual(enabled.color, .green)

        let disabled = FirewallStatus.disabled
        XCTAssertEqual(disabled.displayName, "Disabled")
        XCTAssertEqual(disabled.color, .red)
    }

    func testGatekeeperStatusEnum() {
        let enabled = GatekeeperStatus.enabled
        XCTAssertEqual(enabled.displayName, "Enabled")
        XCTAssertEqual(enabled.color, .green)

        let disabled = GatekeeperStatus.disabled
        XCTAssertEqual(disabled.displayName, "Disabled")
        XCTAssertEqual(disabled.color, .red)
    }

    func testFileVaultStatusEnum() {
        let enabled = FileVaultStatus.enabled
        XCTAssertEqual(enabled.displayName, "Enabled")
        XCTAssertEqual(enabled.color, .green)

        let disabled = FileVaultStatus.disabled
        XCTAssertEqual(disabled.displayName, "Disabled")
        XCTAssertEqual(disabled.color, .red)
    }

    func testSIPStatusEnum() {
        let enabled = SIPStatus.enabled
        XCTAssertEqual(enabled.displayName, "Enabled")
        XCTAssertEqual(enabled.color, .green)

        let disabled = SIPStatus.disabled
        XCTAssertEqual(disabled.displayName, "Disabled")
        XCTAssertEqual(disabled.color, .red)
    }

    func testSystemUpdateStatusEnum() {
        let upToDate = SystemUpdateStatus.upToDate
        XCTAssertEqual(upToDate.displayName, "Up to Date")
        XCTAssertEqual(upToDate.color, .green)

        let updatesAvailable = SystemUpdateStatus.updatesAvailable
        XCTAssertEqual(updatesAvailable.displayName, "Updates Available")
        XCTAssertEqual(updatesAvailable.color, .orange)
    }

    func testSecurityManagerRefresh() {
        let expectation = XCTestExpectation(description: "Refresh completes")

        securityManager.refresh()

        // Wait a bit for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
