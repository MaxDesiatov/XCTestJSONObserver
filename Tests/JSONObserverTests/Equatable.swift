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

@testable import XCTestJSONObserver

func fpAlmostEqual<T: FloatingPoint>(_ first: T, _ second: T) -> Bool {
    if abs(first - second) < .ulpOfOne {
        return true
    }
    return false
}

extension TimedEvent: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.date == rhs.date
    }
}

extension FailedTestCase: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.filePath == rhs.filePath &&
            lhs.lineNumber == rhs.lineNumber &&
            lhs.name == rhs.name &&
            lhs.description == rhs.description
    }
}

extension FinishedTestCase: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state &&
            fpAlmostEqual(lhs.durationInSeconds, rhs.durationInSeconds)
    }
}

extension FinishedTestSuite: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.executionCount == rhs.executionCount &&
            lhs.totalFailureCount == rhs.totalFailureCount &&
            lhs.unexpectedExceptionCount == rhs.unexpectedExceptionCount &&
            fpAlmostEqual(lhs.testDuration, rhs.testDuration) &&
            fpAlmostEqual(lhs.totalDuration, rhs.totalDuration)
    }
}

extension Event: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.testSuiteStarted(lhs), .testSuiteStarted(rhs)):
            return lhs == rhs
        case let (.testCaseStarted(lhs), .testCaseStarted(rhs)):
            return lhs == rhs
        case let (.testCaseFailed(lhs), .testCaseFailed(rhs)):
            return lhs == rhs
        case let (.testCaseFinished(lhs), .testCaseFinished(rhs)):
            return lhs == rhs
        case let (.testSuiteFinished(lhs), .testSuiteFinished(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
