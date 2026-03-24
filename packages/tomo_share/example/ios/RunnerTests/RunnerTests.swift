import Flutter
import UIKit
import XCTest


@testable import tomo_share

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testShareTelegramWithInvalidArgumentsReturnsFlutterError() {
    let plugin = TomoSharePlugin()

    let call = FlutterMethodCall(methodName: "shareTelegram", arguments: [:])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let error = result as? FlutterError
      XCTAssertEqual(error?.code, "invalid_args")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
