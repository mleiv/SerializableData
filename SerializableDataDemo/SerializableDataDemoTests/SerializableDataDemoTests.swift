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

    let sampleJson = "{\"persons\":[{\"name\" : \"Phil Myman\", \"profession\" : \"R&D Lab Scientist\", \"organization\" : \"Veridian Dynamics\", \"notes\" : \"You know what you did.\", \"createdDate\" : \"2009-03-18 19:05:15\", \"modifiedDate\" : \"2010-01-26 20:00:09\"}, {\"name\" : \"Veronica Palmer\", \"profession\" : \"Executive\", \"organization\" : \"Veridian Dynamics\", \"notes\" : \"Friendship. It's the same as stealing.\", \"createdDate\" : \"2009-03-18 19:00:07\", \"modifiedDate\" : \"2010-01-26 23:17:20\"}]}"
    let oneDay = NSTimeInterval(24 * 60 * 60)
    var sevenYearsAgo = NSDate()
    var fiveYearsAgo = NSDate()
    
    override func setUp() {
        super.setUp()
        sevenYearsAgo = NSDate(timeIntervalSinceNow: (-self.oneDay) * 365 * 7)
        fiveYearsAgo = NSDate(timeIntervalSinceNow: (-self.oneDay) * 365 * 5)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNsData() {
        if let jsonData = (sampleJson as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            if let serializableData = try? SerializableData(jsonData: jsonData) {
                if let personsList = serializableData["persons"]?.array {
                    XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                    XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                    let philsStartDate = personsList[0]["createdDate"]?.date ?? NSDate()
                    XCTAssert(philsStartDate.compare(sevenYearsAgo) == .OrderedDescending && philsStartDate.compare(fiveYearsAgo) == .OrderedAscending, "Misread Phil's start date")
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
        if let serializableData = try? SerializableData(jsonString: sampleJson) {
            if let personsList = serializableData["persons"]?.array {
                XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                let philsStartDate = personsList[0]["createdDate"]?.date ?? NSDate()
                    XCTAssert(philsStartDate.compare(sevenYearsAgo) == .OrderedDescending && philsStartDate.compare(fiveYearsAgo) == .OrderedAscending, "Misread Phil's start date")
            } else {
                XCTAssert(false, "Failed to recover array")
            }
        } else {
            XCTAssert(false, "Failed to parse string")
        }
    }
    
    
    func testRepeatedConversions(){
        if let jsonData = (sampleJson as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            if let serializableData = try? SerializableData(jsonData: jsonData) {
                if let serializableData2 = try? SerializableData(jsonString: serializableData.jsonString) {
                    if let personsList = serializableData2["persons"]?.array {
                        XCTAssert(personsList[0]["name"]?.string == "Phil Myman", "Lost Phil's name")
                        XCTAssert(personsList[1]["name"]?.string == "Veronica Palmer", "Lost Veronica's name")
                        let philsStartDate = personsList[0]["createdDate"]?.date ?? NSDate()
                        XCTAssert(philsStartDate.compare(sevenYearsAgo) == .OrderedDescending && philsStartDate.compare(fiveYearsAgo) == .OrderedAscending, "Misread Phil's start date")
                    } else {
                        XCTAssert(false, "Failed to recover array")
                    }
                } else {
                    XCTAssert(false, "Failed to parse string")
                }
            } else {
                XCTAssert(false, "Failed to parse data")
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
        serializableData["date1"] = SerializableData(date: fiveYearsAgo) // dates are tricky
        print("\(serializableData["date1"]?.date) \(fiveYearsAgo)")
        XCTAssert(stringFromDate(serializableData["date1"]?.date ?? NSDate()) == stringFromDate(fiveYearsAgo), "Did not correctly set Date value")
        // it is also hard to compare dates - they report the same up to second, but still don't ==
        serializableData["array1"] = [1, 5]
        XCTAssert(serializableData["array1"]?[1] == 5, "Did not correctly set Array value")
        serializableData["dictionary1"] = ["key1": 1, "key2": 5]
        XCTAssert(serializableData["dictionary1"]?["key2"] == 5, "Did not correctly set Dictionary value")
        let serializedArray = [1,2,5].getData()
        XCTAssert(serializedArray.jsonString == "[\n  1,\n  2,\n  5\n]", "Did not correctly serialize an Array")
        let serializedDictionary = ["key1": "value1"].getData()
        XCTAssert(serializedDictionary.jsonString == "{\n  \"key1\" : \"value1\"\n}", "Did not correctly serialize a Dictionary")
    }
    
    
    func stringFromDate(value: NSDate) -> String? {
        let dateFormatter = NSDateFormatter()
        //add more flexible parsing later
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        return dateFormatter.stringFromDate(value)
    }
}
