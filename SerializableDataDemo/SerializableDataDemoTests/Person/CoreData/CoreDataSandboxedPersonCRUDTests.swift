//
//  CoreDataSandboxedPersonCRUDTests.swift
//  From SimpleCoreDataManagerDemo
//
//  Created by Emily Ivie on 2/19/17.
//  Copyright © 2017 urdnot. All rights reserved.
//

import XCTest
@testable import SerializableDataDemo

class CoreDataSandboxedPersonCRUDTests: XCTestCase {
    // You can run performance tests on these, because they don't use static SimpleCoreDataManager.current.
    // It's just more annoying, because you have to pass the manager all around.
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func getSandboxedManager() -> SimpleSerializedCoreDataManageable {
        return SimpleCoreDataManager(storeName: SimpleCoreDataManager.defaultStoreName, isConfineToMemoryStore: true)
    }
    
    func testCreateRead() {
        testCreateRead(with: getSandboxedManager())
    }
    func testCreateRead(with manager: SimpleSerializedCoreDataManageable) {
        let newPerson = createPhil(with: manager)
        let newPersonId = newPerson?.id
        // reload to make sure the value was created
        let phil = CoreDataPerson.get(name: "Phil Myman", with: manager)
        XCTAssert(phil != nil, "Person was not created")
        XCTAssert(phil?.id == newPersonId, "Created Person id not saved correctly")
    }
    
    func testReadAll() {
        testReadAll(with: getSandboxedManager())
    }
    func testReadAll(with manager: SimpleSerializedCoreDataManageable) {
        _ = createPhil(with: manager)
        _ = createLem(with: manager)
        _ = createVeronica(with: manager)
        let persons = CoreDataPerson.getAll(with: manager).sorted(by: CoreDataPerson.sort)
        XCTAssert(persons.count == 3, "All Persons were not created")
        XCTAssert(persons.first?.name == "Lem Hewitt", "Persons sorted incorrectly")
    }
    
    func testReadAllPerformance() {
        measure {
            self.testReadAll(with: self.getSandboxedManager())
        }
    }
    
    func testUpdate() {
        testUpdate(with: getSandboxedManager())
    }
    func testUpdate(with manager: SimpleSerializedCoreDataManageable) {
        _ = createPhil(with: manager)
        // reload to make sure the value was created
        var phil = CoreDataPerson.get(name: "Phil Myman", with: manager)
        XCTAssert(phil != nil, "Person was not created")
        phil?.name = "Byron McNertny"
        phil?.profession = "Cowboy"
        phil?.organization = "Some Ranch"
        _ = phil?.save(with: manager)
        let byron = CoreDataPerson.get(name: "Byron McNertny", with: manager)
        XCTAssert(byron != nil, "Updated Person not found in the store")
        XCTAssert(byron?.name == "Byron McNertny", "Updated Person has incorrect values")
        let missingPhil = CoreDataPerson.get(name: "Phil Myman", with: manager)
        XCTAssert(CoreDataPerson.getCount(with: manager) == 1, "Saved multiple copies of same person")
        XCTAssert(missingPhil == nil, "Updated Person has older values in the store")
    }
    
    func testDelete() {
        testDelete(with: getSandboxedManager())
    }
    func testDelete(with manager: SimpleSerializedCoreDataManageable) {
        _ = createPhil(with: manager)
        // reload to make sure the value was created
        var phil = CoreDataPerson.get(name: "Phil Myman", with: manager)
        XCTAssert(phil != nil, "Person was not created")
        _ = phil?.delete(with: manager)
        let missingPhil = CoreDataPerson.get(name: "Phil Myman", with: manager)
        XCTAssert(missingPhil == nil, "Deleted Person still found in store")
    }
    
    func testDeleteAll() {
        testDeleteAll(with: getSandboxedManager())
    }
    func testDeleteAll(with manager: SimpleSerializedCoreDataManageable) {
        testReadAll(with: manager)
        _ = CoreDataPerson.deleteAll(with: manager)
        XCTAssert(CoreDataPerson.getCount(with: manager) == 0, "Person deleteAll failed")
    }
    
    private func createPhil(with manager: SimpleSerializedCoreDataManageable? = nil) -> CoreDataPerson? {
        var phil = CoreDataPerson(serializedString: "{\"id\": \"\(UUID())\", \"name\": \"Phil Myman\", \"profession\": \"R&D Lab Scientist\", \"organization\": \"Veridian Dynamics\", \"notes\": \"You know what you did.\", \"createdDate\": \"2010-03-18 19:05:15\", \"modifiedDate\": \"2010-01-26 20:00:09\"}")
        _ = phil?.save(with: manager)
        return phil
    }
    
    private func createLem(with manager: SimpleSerializedCoreDataManageable? = nil) -> CoreDataPerson? {
        var lem = CoreDataPerson(serializedString: "{\"id\": \"\(UUID())\", \"name\": \"Lem Hewitt\", \"profession\": \"R&D Lab Scientist\", \"organization\": \"Veridian Dynamics\", \"notes\": \"You heard the statistically average lady.\", \"createdDate\": \"2017-02-20 13:14:00\", \"modifiedDate\": \"2017-02-20 13:14:00\"}")
        _ = lem?.save(with: manager)
        return lem
    }
    
    private func createVeronica(with manager: SimpleSerializedCoreDataManageable? = nil) -> CoreDataPerson? {
        var veronica = CoreDataPerson(serializedString: "{\"id\": \"\(UUID())\", \"name\": \"Veronica Palmer\", \"profession\": \"Executive\", \"organization\": \"Veridian Dynamics\", \"notes\": \"Friendship. It's the same as stealing.\", \"createdDate\": \"2010-03-18 19:00:07\", \"modifiedDate\": \"2010-01-26 23:17:20\"}")
        _ = veronica?.save(with: manager)
        return veronica
    }
}
