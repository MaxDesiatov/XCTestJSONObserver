// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  JSONObserver.swift
//  Prints test progress to stdout encoded as JSON
//

import Foundation
import XCTest

struct TimedEvent: Codable, Equatable {
    let name: String
    let date: Date
}

struct FailedTestCase: Codable, Equatable {
    let filePath: String?
    let lineNumber: Int
    let name: String
    let description: String
}

struct FinishedTestCase: Codable, Equatable {
    enum State: String, Codable {
        case skipped
        case passed
        case failed
    }

    let state: State
    let durationInSeconds: TimeInterval
}

struct FinishedTestSuite: Codable, Equatable {
    let executionCount: Int
    let totalFailureCount: Int
    let unexpectedExceptionCount: Int
    let testDuration: TimeInterval
    let totalDuration: TimeInterval
}

enum Event: Codable, Equatable {
    enum CodingError: Error {
        case invalidVersion
    }

    enum Kind: String, Codable {
        case testSuiteStarted
        case testCaseStarted
        case testCaseFailed
        case testCaseFinished
        case testSuiteFinished
    }

    private enum CodingKeys: CodingKey {
        case version
        case kind
        case value
    }

    case testSuiteStarted(TimedEvent)
    case testCaseStarted(TimedEvent)
    case testCaseFailed(FailedTestCase)
    case testCaseFinished(FinishedTestCase)
    case testSuiteFinished(FinishedTestSuite)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let version = try container.decode(Int.self, forKey: .version)
        guard version == 0 else { throw CodingError.invalidVersion }

        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .testSuiteStarted:
            self = .testSuiteStarted(try TimedEvent(from: decoder))
        case .testCaseStarted:
            self = .testCaseStarted(try TimedEvent(from: decoder))
        case .testCaseFailed:
            self = .testCaseFailed(try FailedTestCase(from: decoder))
        case .testCaseFinished:
            self = .testCaseFinished(try FinishedTestCase(from: decoder))
        case .testSuiteFinished:
            self = .testSuiteFinished(try FinishedTestSuite(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: CodingKeys.version)

        switch self {
        case let .testSuiteStarted(value):
            try container.encode(Kind.testSuiteStarted, forKey: CodingKeys.kind)
            try container.encode(value, forKey: CodingKeys.value)
        case let .testCaseStarted(value):
            try container.encode(Kind.testCaseStarted, forKey: CodingKeys.kind)
            try container.encode(value, forKey: CodingKeys.value)
        case let .testCaseFailed(value):
            try container.encode(Kind.testCaseFailed, forKey: CodingKeys.kind)
            try container.encode(value, forKey: CodingKeys.value)
        case let .testCaseFinished(value):
            try container.encode(Kind.testCaseFinished, forKey: CodingKeys.kind)
            try container.encode(value, forKey: CodingKeys.value)
        case let .testSuiteFinished(value):
            try container.encode(Kind.testSuiteFinished, forKey: CodingKeys.kind)
            try container.encode(value, forKey: CodingKeys.value)
        }
    }
}

/// Prints JSON representations of each XCTestObservation event to stdout.
internal class JSONObserver: NSObject, XCTestObservation {
    #if !os(WASI)
    func testBundleWillStart(_ testBundle: Bundle) {}
    #endif

    func testSuiteWillStart(_ testSuite: XCTestSuite) {
        printAndFlush("Test Suite '\(testSuite.name)' started at \(dateFormatter.string(from: testSuite.testRun!.startDate!))")
    }

    func testCaseWillStart(_ testCase: XCTestCase) {
        printAndFlush("Test Case '\(testCase.name)' started at \(dateFormatter.string(from: testCase.testRun!.startDate!))")
    }

    func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        let file = filePath ?? "<unknown>"
        printAndFlush("\(file):\(lineNumber): error: \(testCase.name) : \(description)")
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        let testRun = testCase.testRun!

        let verb: String
        if testRun.hasSucceeded {
            if testRun.hasBeenSkipped {
                verb = "skipped"
            } else {
                verb = "passed"
            }
        } else {
            verb = "failed"
        }

        printAndFlush("Test Case '\(testCase.name)' \(verb) (\(formatTimeInterval(testRun.totalDuration)) seconds)")
    }

    func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        let testRun = testSuite.testRun!
        let verb = testRun.hasSucceeded ? "passed" : "failed"
        printAndFlush("Test Suite '\(testSuite.name)' \(verb) at \(dateFormatter.string(from: testRun.stopDate!))")

        let tests = testRun.executionCount == 1 ? "test" : "tests"
        let skipped = testRun.skipCount > 0 ? "\(testRun.skipCount) test\(testRun.skipCount != 1 ? "s" : "") skipped and " : ""
        let failures = testRun.totalFailureCount == 1 ? "failure" : "failures"

        printAndFlush("""
        \t Executed \(testRun.executionCount) \(tests), \
        with \(skipped)\
        \(testRun.totalFailureCount) \(failures) \
        (\(testRun.unexpectedExceptionCount) unexpected) \
        in \(formatTimeInterval(testRun.testDuration)) (\(formatTimeInterval(testRun.totalDuration))) seconds
        """
        )
    }

    #if !os(WASI)
    func testBundleDidFinish(_ testBundle: Bundle) {}
    #endif

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        #if !os(WASI)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        #endif
        return formatter
    }()

    fileprivate func printAndFlush(_ message: String) {
        print(message)
        #if !os(Android) && !os(WASI)
        fflush(stdout)
        #endif
    }

    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        String(round(timeInterval * 1000.0) / 1000.0)
    }
}
