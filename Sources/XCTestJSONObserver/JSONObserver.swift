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

public struct TimedEvent: Codable {
    public let name: String
    public let date: Date
}

public struct FailedTestCase: Codable {
    public let filePath: String?
    public let lineNumber: Int
    public let name: String
    public let description: String
}

public struct FinishedTestCase: Codable {
    public enum State: String, Codable, CaseIterable {
        case skipped
        case passed
        case failed
    }

    public let state: State
    public let durationInSeconds: TimeInterval
}

public struct FinishedTestSuite: Codable {
    public let executionCount: Int
    public let totalFailureCount: Int
    public let unexpectedExceptionCount: Int
    public let testDuration: TimeInterval
    public let totalDuration: TimeInterval
}

public enum Event: Codable {
    public enum CodingError: Error {
        case invalidVersion
    }

    public enum Kind: String, Codable, CaseIterable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let version = try container.decode(Int.self, forKey: .version)
        guard version == 0 else { throw CodingError.invalidVersion }

        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .testSuiteStarted:
            self = .testSuiteStarted(try container.decode(TimedEvent.self, forKey: .value))
        case .testCaseStarted:
            self = .testCaseStarted(try container.decode(TimedEvent.self, forKey: .value))
        case .testCaseFailed:
            self = .testCaseFailed(try container.decode(FailedTestCase.self, forKey: .value))
        case .testCaseFinished:
            self = .testCaseFinished(try container.decode(FinishedTestCase.self, forKey: .value))
        case .testSuiteFinished:
            self = .testSuiteFinished(try container.decode(FinishedTestSuite.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(0, forKey: CodingKeys.version)

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
public class JSONObserver: NSObject, XCTestObservation {
    let handler: (Event) -> ()

    public init(handler: @escaping (Event) -> ()) {
        self.handler = handler
    }

    #if !os(WASI)
    public func testBundleWillStart(_ testBundle: Bundle) {}
    #endif

    public func testSuiteWillStart(_ testSuite: XCTestSuite) {
        handler(Event.testSuiteStarted(.init(
            name: testSuite.name,
            date: testSuite.testRun!.startDate!
        )))
    }

    public func testCaseWillStart(_ testCase: XCTestCase) {
        handler(Event.testSuiteStarted(.init(
            name: testCase.name,
            date: testCase.testRun!.startDate!
        )))
    }

    public func testCase(
        _ testCase: XCTestCase,
        didFailWithDescription description: String,
        inFile filePath: String?,
        atLine lineNumber: Int
    ) {
        handler(Event.testCaseFailed(.init(
            filePath: filePath,
            lineNumber: lineNumber,
            name: testCase.name,
            description: description
        )))
    }

    public func testCaseDidFinish(_ testCase: XCTestCase) {
        let testRun = testCase.testRun!

        let state: FinishedTestCase.State
        if testRun.hasSucceeded {
            if testRun.hasBeenSkipped {
                state = .skipped
            } else {
                state = .passed
            }
        } else {
            state = .failed
        }

        handler(Event.testCaseFinished(.init(
            state: state,
            durationInSeconds: testRun.totalDuration
        )))
    }

    public func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        let testRun = testSuite.testRun!

        handler(Event.testSuiteFinished(.init(
            executionCount: testRun.executionCount,
            totalFailureCount: testRun.totalFailureCount,
            unexpectedExceptionCount: testRun.unexpectedExceptionCount,
            testDuration: testRun.testDuration,
            totalDuration: testRun.totalDuration
        )))
    }

    #if !os(WASI)
    public func testBundleDidFinish(_ testBundle: Bundle) {}
    #endif
}
