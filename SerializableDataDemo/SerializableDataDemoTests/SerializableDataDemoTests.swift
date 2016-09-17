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

    let sampleJson = "{\"persons\":[{\"name\" : \"Phil Myman\", \"profession\" : \"R&D Lab Scientist\", \"organization\" : \"Veridian Dynamics\", \"notes\" : \"You know what you did.\", \"createdDate\" : \"2010-03-18 19:05:15\", \"modifiedDate\" : \"2010-01-26 20:00:09\"}, {\"name\" : \"Veronica Palmer\", \"profession\" : \"Executive\", \"organization\" : \"Veridian Dynamics\", \"notes\" : \"Friendship. It's the same as stealing.\", \"createdDate\" : \"2010-03-18 19:00:07\", \"modifiedDate\" : \"2010-01-26 23:17:20\"}]}"
    let oneDay = TimeInterval(24 * 60 * 60)
    var sevenYearsAgo = Date()
    var fiveYearsAgo = Date()
    
    override func setUp() {
        super.setUp()
        sevenYearsAgo = Date(timeIntervalSinceNow: (-self.oneDay) * 365 * 7)
        fiveYearsAgo = Date(timeIntervalSinceNow: (-self.oneDay) * 365 * 5)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNsData() {
        if let jsonData = (sampleJson as NSString).data(using: String.Encoding.utf8.rawValue) {
            if let serializableData = try? SerializableData(jsonData: jsonData) {
                if let personsList = serializableData["persons"]?.array {
                    XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                    XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                    let philsStartDate = personsList[0]["createdDate"]?.date ?? Date()
                    XCTAssert(philsStartDate.compare(sevenYearsAgo) == .orderedDescending && philsStartDate.compare(fiveYearsAgo) == .orderedAscending, "Misread Phil's start date")
                } else {
                    XCTAssert(false, "Failed to recover array")
                }
            } else {
                XCTAssert(false, "Failed to parse data")
            }
        } else {
            XCTAssert(false, "Failed to create data")
        }
    }
    
    func testString() {
        do {
            let serializableData = try SerializableData(jsonString: sampleJson)
            if let personsList = serializableData["persons"]?.array {
                XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                let philsStartDate = personsList[0]["createdDate"]?.date ?? Date()
                    XCTAssert(philsStartDate.compare(sevenYearsAgo) == .orderedDescending && philsStartDate.compare(fiveYearsAgo) == .orderedAscending, "Misread Phil's start date")
            } else {
                XCTAssert(false, "Failed to recover array")
            }
        } catch {
            XCTAssert(false, "Failed to parse string")
        }
    }
    
    
    func testRepeatedConversions(){
        if let jsonData = (sampleJson as NSString).data(using: String.Encoding.utf8.rawValue) {
            do {
                let serializableData = try SerializableData(jsonData: jsonData)
                let serializableData2 = try SerializableData(jsonString: serializableData.jsonString)
                if let personsList = serializableData2["persons"]?.array {
                    XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                    XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                    let philsStartDate = personsList[0]["createdDate"]?.date ?? Date()
                    XCTAssert(philsStartDate.compare(sevenYearsAgo) == .orderedDescending && philsStartDate.compare(fiveYearsAgo) == .orderedAscending, "Misread Phil's start date")
                } else {
                    XCTAssert(false, "Failed to recover array")
                }
            } catch {
                XCTAssert(false, "Failed to parse string")
            }
        } else {
            XCTAssert(false, "Failed to create data")
        }
    }
    
    func testCreateData() {
        var serializableData = SerializableData()
        serializableData["test1"] = "test"
        XCTAssert(serializableData["test1"]?.string == "test", "Did not correctly set String value")
        serializableData["number1"] = 5
        XCTAssert(serializableData["number1"]?.int == 5, "Did not correctly set Int value")
        serializableData["number2"] = 5.01
        XCTAssert(serializableData["number2"]?.float == 5.01, "Did not correctly set Float value")
        XCTAssert(serializableData["number2"]?.double == 5.01, "Did not correctly set Double value")
        serializableData["bool1"] = true
        XCTAssert(serializableData["bool1"]?.bool == true, "Did not correctly set Bool value")
        serializableData["date1"] = SerializableData.safeInit(date: fiveYearsAgo) // dates are tricky
        print("\(serializableData["date1"]?.date) \(fiveYearsAgo)")
        XCTAssert(stringFromDate(serializableData["date1"]?.date ?? Date()) == stringFromDate(fiveYearsAgo), "Did not correctly set Date value")
        // it is also hard to compare dates - they report the same up to second, but still don't ==
        serializableData["array1"] = [1, 5]
        XCTAssert(serializableData["array1"]?[1] == 5, "Did not correctly set Array value")
        serializableData["dictionary1"] = ["key1": 1, "key2": 5]
        XCTAssert(serializableData["dictionary1"]?["key2"] == 5, "Did not correctly set Dictionary value")
        let serializedArray: SerializableData = [1,2,5]
        XCTAssert(serializedArray.jsonString == "[\n  1,\n  2,\n  5\n]", "Did not correctly serialize an Array")
        let serializedDictionary: SerializableData = ["key1": "value1"]
        XCTAssert(serializedDictionary.jsonString == "{\n  \"key1\" : \"value1\"\n}", "Did not correctly serialize a Dictionary")
    }
    
    func testCgFloat() {
        var serializableData = SerializableData()
        // sorry, this won't work
//        serializableData["cgfloat"] = CGFloat(5)
        // but this will
        let cgFloat1 = CGFloat(5)
        serializableData["cgfloat"] = cgFloat1.getData()
        // and so will this:
        serializableData["cgfloats"] = [cgFloat1, CGFloat(1.5)]
        XCTAssert(serializableData["cgfloat"]?.cgFloat == cgFloat1, "Did not correctly serialize CGFloat")
        XCTAssert(serializableData["cgfloats"]?[0]?.cgFloat == cgFloat1, "Did not correctly serialize CGFloat Array")
    }
    
    func testUrl() {
        var serializableData = SerializableData()
        // sorry, this won't work
//        serializableData["url"] = NSURL(string: "http://example.com/")
        // but this will
        let nsUrl = URL(string: "http://example.com/")
        serializableData["url"] = nsUrl?.getData()
        // and so will this:
        let urls: [SerializedDataStorable?] = [nsUrl, URL(string: "http://yahoo.com/")]
        serializableData["urls"] = SerializableData.safeInit(urls)
        XCTAssert(serializableData["url"]?.url == nsUrl, "Did not correctly serialize CGFloat")
        XCTAssert(serializableData["urls"]?[0]?.url == nsUrl, "Did not correctly serialize CGFloat Array")
    }
    
    
    func testFileReadWrite() {
        do {
            let serializableData = try SerializableData(jsonString: sampleJson)
            let fileName = "store.data"
            if serializableData.store(fileName: fileName) {
                let retrievedData = try SerializableData(fileName: fileName)
                if let personsList = retrievedData["persons"]?.array {
                    XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                } else {
                    XCTAssert(false, "Failed to retrieve array from file")
                }
                if retrievedData.delete(fileName: fileName) {
                    if let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                        let path = (documents as NSString).appendingPathComponent(fileName)
                        XCTAssert(FileManager.default.fileExists(atPath: path) == false, "Reported file delete but file exists")
                    } else {
                        XCTAssert(false, "Problem with documents folder")
                    }
                } else {
                    XCTAssert(false, "Failed to delete file")
                }
            } else {
                XCTAssert(false, "Failed to write file")
            }
        } catch {
            XCTAssert(false, "Failed to parse string")
        }
    }
    
    func stringFromDate(_ value: Date) -> String? {
        let dateFormatter = DateFormatter()
        //add more flexible parsing later
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: value)
    }
}
