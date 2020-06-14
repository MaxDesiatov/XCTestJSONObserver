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
import SwiftCheck
import XCTest
@testable import XCTestJSONObserver

extension Date: Arbitrary {
    public static var arbitrary: Gen<Date> {
        TimeInterval.arbitrary.map { Date(timeIntervalSince1970: $0) }
    }
}

extension TimedEvent: Arbitrary {
    public static var arbitrary: Gen<TimedEvent> {
        .compose { .init(name: $0.generate(), date: $0.generate()) }
    }
}

extension FailedTestCase: Arbitrary {
    public static var arbitrary: Gen<FailedTestCase> {
        .compose {
            .init(
                filePath: $0.generate(),
                lineNumber: $0.generate(),
                name: $0.generate(),
                description: $0.generate()
            )
        }
    }
}

extension FinishedTestCase.State: Arbitrary {
    public static var arbitrary: Gen<FinishedTestCase.State> {
        .fromElements(of: FinishedTestCase.State.allCases)
    }
}

extension FinishedTestCase: Arbitrary {
    public static var arbitrary: Gen<FinishedTestCase> {
        .compose { .init(state: $0.generate(), durationInSeconds: $0.generate()) }
    }
}

extension FinishedTestSuite: Arbitrary {
    public static var arbitrary: Gen<FinishedTestSuite> {
        .compose {
            .init(
                executionCount: $0.generate(),
                totalFailureCount: $0.generate(),
                unexpectedExceptionCount: $0.generate(),
                testDuration: $0.generate(),
                totalDuration: $0.generate()
            )
        }
    }
}

extension Event.Kind: Arbitrary {
    public static var arbitrary: Gen<Event.Kind> {
        .fromElements(of: Event.Kind.allCases)
    }
}

extension Event: Arbitrary {
    public static var arbitrary: Gen<Event> {
        .compose {
            let kind: Event.Kind = $0.generate()

            switch kind {
            case .testSuiteStarted:
                return .testSuiteStarted($0.generate())
            case .testCaseStarted:
                return .testCaseStarted($0.generate())
            case .testCaseFailed:
                return .testCaseFailed($0.generate())
            case .testCaseFinished:
                return .testCaseFinished($0.generate())
            case .testSuiteFinished:
                return .testSuiteFinished($0.generate())
            }
        }
    }
}

func doublesAreEqual(first: Double, second: Double) -> Bool {
    if fabs(first - second) < .ulpOfOne {
        return true
    }
    return false
}

final class PropertyTests: XCTestCase {
    func testReversibleEncoding() throws {
        property("Event encoding is reversible") <- forAll { (event: Event) in
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(event)
            let decoder = JSONDecoder()
            let decodedEvent = try decoder.decode(Event.self, from: encoded)

            return decodedEvent == event
        }
    }
}
