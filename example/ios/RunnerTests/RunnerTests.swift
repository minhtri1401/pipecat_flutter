import Flutter
import UIKit
import XCTest

@testable import pipecat

class RunnerTests: XCTestCase {
  func testPluginInstantiates() {
    let plugin = PipecatFlutterPlugin()
    XCTAssertNotNil(plugin)
  }
}
