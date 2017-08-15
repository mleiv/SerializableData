//
//  SerializableDataDemoTests.swift
//  SerializableDataDemoTests
//
//  Created by Emily Ivie on 10/16/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import XCTest
@testable import SerializableDataDemo

class SerializableDataDemoTests: XCTestCase {

    let sampleJson = """
        {
            "persons": [{
                "id": "\(UUID())",
                "name": "Phil Myman",
                "profession": "R&D Lab Scientist",
                "organization": "Veridian Dynamics",
                "notes": "You know what you did.",
                "createdDate": "2010-03-18 19:05:15",
                "modifiedDate": "2010-01-26 20:00:09"
            }, {
                "id": "\(UUID())",
                "name": "Veronica Palmer",
                "profession": "Executive",
                "organization": "Veridian Dynamics",
                "notes": "Friendship. It's the same as stealing.",
                "createdDate": "2010-03-18 19:00:07",
                "modifiedDate": "2010-01-26 23:17:20"
            }]
        }
    """
    let oneDay = TimeInterval(24 * 60 * 60)
    var tenYearsAgo = Date()
    var fiveYearsAgo = Date()
    
    override func setUp() {
        super.setUp()
        SimpleCoreDataManager.current = getSandboxedManager()
        tenYearsAgo = Date(timeIntervalSinceNow: (-self.oneDay) * 365 * 10)
        fiveYearsAgo = Date(timeIntervalSinceNow: (-self.oneDay) * 365 * 5)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func getSandboxedManager() -> SimpleCoreDataManager {
        return SimpleCoreDataManager(storeName: SimpleCoreDataManager.defaultStoreName, isConfineToMemoryStore: true)
    }

    func testData() {
        if let data = sampleJson.data(using: .utf8) {
            if let list = try? SimpleCoreDataManager.current.decoder.decode([String:[UserDefaultsPerson]].self, from: data),
                let persons = list["persons"] {
                XCTAssert(persons[0].name == "Phil Myman", "Lost Phil's name")
                XCTAssert(persons[1].name == "Veronica Palmer", "Lost Veronica's name")
                let philsStartDate = persons[0].createdDate
                XCTAssert(philsStartDate.compare(tenYearsAgo) == .orderedDescending && philsStartDate.compare(fiveYearsAgo) == .orderedAscending, "Misread Phil's start date")
            } else {
                XCTAssert(false, "Failed to parse data")
            }
        } else {
            XCTAssert(false, "Failed to create data")
        }
    }
    func testRepeatedConversions(){
        if let data = sampleJson.data(using: .utf8) {
            do {
                let list1 = try SimpleCoreDataManager.current.decoder.decode([String:[UserDefaultsPerson]].self, from: data)
                let data2 = try SimpleCoreDataManager.current.encoder.encode(list1)
                let list2 = try SimpleCoreDataManager.current.decoder.decode([String:[UserDefaultsPerson]].self, from: data2)
                let persons2 = list2["persons"] ?? []
                XCTAssert(persons2[0].name == "Phil Myman", "Lost Phil's name")
                XCTAssert(persons2[1].name == "Veronica Palmer", "Lost Veronica's name")
                let philsStartDate = persons2[0].createdDate
                XCTAssert(philsStartDate.compare(tenYearsAgo) == .orderedDescending && philsStartDate.compare(fiveYearsAgo) == .orderedAscending, "Misread Phil's start date")
            } catch {
                XCTAssert(false, "Failed to parse string")
            }
        } else {
            XCTAssert(false, "Failed to create data")
        }
    }
}
