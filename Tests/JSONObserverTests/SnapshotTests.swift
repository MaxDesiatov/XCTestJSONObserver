// Copyright 2020 XCTestJSONObserver contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SnapshotTesting
import XCTest
@testable import XCTestJSONObserver

func assert(_ event: Event, _ name: String = #function) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]

    let encoded = try encoder.encode(event)

    assertSnapshot(matching: String(data: encoded, encoding: .utf8)!, as: .lines, testName: name)

    let decoder = JSONDecoder()

    let decoded = try decoder.decode(Event.self, from: encoded)
    XCTAssertEqual(decoded, event)
}

final class SnapshotTests: XCTestCase {
    func testSuiteStarted() throws {
        try assert(.testSuiteStarted(.init(
            name: "testSuite",
            date: Date(timeIntervalSince1970: 12345)
        )))
    }

    func testCaseStarted() throws {
        try assert(.testCaseStarted(.init(
            name: "testCase",
            date: Date(timeIntervalSince1970: -54321)
        )))
    }

    func testCaseFailed() throws {
        try assert(.testCaseFailed(.init(
            filePath: "File.swift",
            lineNumber: 42,
            name: "testCase",
            description: "testCase failed"
        )))
    }

    func testCaseFinished() throws {
        try assert(.testCaseFinished(.init(
            state: .passed,
            durationInSeconds: 4.2
        )))
    }

    func testSuiteFinished() throws {
        try assert(.testSuiteFinished(.init(
            executionCount: 42,
            totalFailureCount: 24,
            unexpectedExceptionCount: 1,
            testDuration: 1.2,
            totalDuration: 12.3
        )))
    }
}
