import XCTest
@testable import pipecat

final class ConnectParamsParserTests: XCTestCase {

    func testDailyWithToken() throws {
        let dict: [String: Any] = [
            "roomUrl": "https://x.daily.co/y",
            "token":   "t",
        ]
        let p = try parseDailyConnectionParams(dict)
        XCTAssertEqual(p.roomUrl, "https://x.daily.co/y")
        XCTAssertEqual(p.token, "t")
    }

    func testDailyWithoutToken() throws {
        let dict: [String: Any] = ["roomUrl": "https://x.daily.co/y"]
        let p = try parseDailyConnectionParams(dict)
        XCTAssertEqual(p.roomUrl, "https://x.daily.co/y")
        XCTAssertNil(p.token)
    }

    func testDailyMissingRoomUrlThrows() {
        let dict: [String: Any] = ["token": "t"]
        XCTAssertThrowsError(try parseDailyConnectionParams(dict)) { error in
            guard case PipecatPluginError.invalidParams(let msg) = error else {
                return XCTFail("expected invalidParams, got \(error)")
            }
            XCTAssertTrue(msg.contains("roomUrl"))
        }
    }

    func testSmallWebRTCParsed() throws {
        let dict: [String: Any] = ["webrtcUrl": "https://x/offer"]
        let p = try parseSmallWebRTCConnectionParams(dict)
        XCTAssertEqual(p.webrtcRequestParams.endpoint.absoluteString, "https://x/offer")
    }

    func testSmallWebRTCMissingUrlThrows() {
        let dict: [String: Any] = [:]
        XCTAssertThrowsError(try parseSmallWebRTCConnectionParams(dict)) { error in
            guard case PipecatPluginError.invalidParams = error else {
                return XCTFail("expected invalidParams, got \(error)")
            }
        }
    }

    func testSmallWebRTCInvalidUrlThrows() {
        // URL(string: "") returns nil — exercises the URL-check branch.
        let dict: [String: Any] = ["webrtcUrl": ""]
        XCTAssertThrowsError(try parseSmallWebRTCConnectionParams(dict))
    }
}
