//
//  CoreDataPersonCRUDTests.swift
//  From SimpleCoreDataManagerDemo
//
//  Created by Emily Ivie on 2/19/17.
//  Copyright © 2017 urdnot. All rights reserved.
//

import XCTest
@testable import SerializableDataDemo

class CoreDataPersonCRUDTests: XCTestCase {

    // can't do performance tests in this version
    
    private let jsonCoder = JsonCoder()
    
    override func setUp() {
        super.setUp()
        SimpleCoreDataManager.current = getSandboxedManager()
    }
    
    override func tearDown() {
        _ = CoreDataPerson.deleteAll()
        super.tearDown()
    }
    
    private func getSandboxedManager() -> SimpleCoreDataManager {
        return SimpleCoreDataManager(storeName: SimpleCoreDataManager.defaultStoreName, isConfineToMemoryStore: true)
    }
    
    func testCreateRead() {
        let newPerson = createPhil()
        let newPersonId = newPerson?.id
        // reload to make sure the value was created
        let phil = CoreDataPerson.get(name: "Phil Myman")
        XCTAssert(phil != nil, "Person was not created")
        XCTAssert(phil?.id == newPersonId, "Created Person id not saved correctly")
    }
    
    func testReadAll() {
        _ = createPhil()
        _ = createLem()
        _ = createVeronica()
        let persons = CoreDataPerson.getAll().sorted(by: CoreDataPerson.sort)
        XCTAssert(persons.count == 3, "All Persons were not created")
        XCTAssert(persons.first?.name == "Lem Hewitt", "Persons sorted incorrectly")
    }
    
//    func testReadAllPerformance() {
//        measure {
//            self.testReadAll()
//        }
//    }
    
    func testUpdate() {
        _ = createPhil()
        // reload to make sure the value was created
        var phil = CoreDataPerson.get(name: "Phil Myman")
        XCTAssert(phil != nil, "Person was not created")
        phil?.name = "Byron McNertny"
        phil?.profession = "Cowboy"
        phil?.organization = "Some Ranch"
        _ = phil?.save()
        let byron = CoreDataPerson.get(name: "Byron McNertny")
        XCTAssert(byron != nil, "Updated Person not found in the store")
        XCTAssert(byron?.name == "Byron McNertny", "Updated Person has incorrect values")
        let missingPhil = CoreDataPerson.get(name: "Phil Myman")
        XCTAssert(CoreDataPerson.getCount() == 1, "Saved multiple copies of same person")
        XCTAssert(missingPhil == nil, "Updated Person has older values in the store")
    }
    
    func testDelete() {
        _ = createPhil()
        // reload to make sure the value was created
        var phil = CoreDataPerson.get(name: "Phil Myman")
        XCTAssert(phil != nil, "Person was not created")
        _ = phil?.delete()
        let missingPhil = CoreDataPerson.get(name: "Phil Myman")
        XCTAssert(missingPhil == nil, "Deleted Person still found in store")
    }
    
    func testDeleteAll() {
        testReadAll()
        _ = CoreDataPerson.deleteAll()
        XCTAssert(CoreDataPerson.getCount() == 0, "Person deleteAll failed")
    }

    private func createPhil(with manager: CodableCoreDataManageable? = nil) -> CoreDataPerson? {
        if let data = "{\"id\": \"\(UUID())\", \"name\": \"Phil Myman\", \"profession\": \"R&D Lab Scientist\", \"organization\": \"Veridian Dynamics\", \"notes\": \"You know what you did.\", \"createdDate\": \"2010-03-18 19:05:15\", \"modifiedDate\": \"2010-01-26 20:00:09\"}".data(using: .utf8),
            var phil = try? jsonCoder.decode(CoreDataPerson.self, from: data) {
            _ = phil.save(with: manager)
            return phil
        }
        return nil
    }

    private func createLem(with manager: CodableCoreDataManageable? = nil) -> CoreDataPerson? {
        if let data = "{\"id\": \"\(UUID())\", \"name\": \"Lem Hewitt\", \"profession\": \"R&D Lab Scientist\", \"organization\": \"Veridian Dynamics\", \"notes\": \"You heard the statistically average lady.\", \"createdDate\": \"2017-02-20 13:14:00\", \"modifiedDate\": \"2017-02-20 13:14:00\"}".data(using: .utf8),
            var lem = try? jsonCoder.decode(CoreDataPerson.self, from: data) {
            _ = lem.save(with: manager)
            return lem
        }
        return nil
    }

    private func createVeronica(with manager: CodableCoreDataManageable? = nil) -> CoreDataPerson? {
        if let data = "{\"id\": \"\(UUID())\", \"name\": \"Veronica Palmer\", \"profession\": \"Executive\", \"organization\": \"Veridian Dynamics\", \"notes\": \"Friendship. It's the same as stealing.\", \"createdDate\": \"2010-03-18 19:00:07\", \"modifiedDate\": \"2010-01-26 23:17:20\"}".data(using: .utf8),
            var veronica = try? jsonCoder.decode(CoreDataPerson.self, from: data) {
            _ = veronica.save(with: manager)
            return veronica
        }
        return nil
    }
    
}
