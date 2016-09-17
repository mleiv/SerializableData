# SerializableData

**An easy Swift 3.0 library to get/set json-type data, usable in NSUserDefaults and CoreData**

## Including in Your App

There is no CocoaPods or Carthage installation option. If you want this, just copy in the necessary code files (helpfully placed in the **Necessary Code Files** folder inside this repo) and you're set!

* SerializableData.swift
* SerializedDataStorable.swift
* SerializedDataRetrievable.swift
* StringExtension.swift
* DictionaryExtension.swift

## News 2016-09-17

Upgraded to Swift 3.0. It was a bit rushed, so some functionality has changed or been disabled. I added SerializableData.safeInit() as a non-throwing version of SerializableData() - it returns a null data object when it fails. .getData() no longer works on arrays or dictionaries, but they are currently initializing better via the standard SerializableData() anyway.

## News 2015-11-10

Added file read/write functions.

```swift

do {
    let fileName = "store.data"
    if serializableData.store(fileName: fileName) {
        let retrievedData = try SerializableData(fileName: fileName)
        // serializableData and retrievedData should be identical
    }
}
```

## Storing and Retrieving JSON in SerializableData

You can easily parse JSON from either a string or NSData object. You can also retrieve a json-formatted or url-string-formatted version of any SerializableData object.

```swift

	if let serializableData = try? SerializableData(jsonData: someNSData) {
		if let key1 = serializableData["key1"]?.string {
			// do something with values
		}
	}
	if let serializableData = try? SerializableData(jsonString: someJSONString) {
		if let key1 = serializableData["key1"]?.string {
			// do something with values
		}
		let storableValue = serializableData.jsonString // returns "{\"key1\":\"value1\",\"key2\":\"value2\"}"
		let urlString = serializableData.urlString // returns "key1=value&key2=value2"
	}
```

## Data Types recognized by default

There are several data types that can be stored as SerializableData with no extra effort. This includes String, Int, Double, Float, Bool, NSDate, NSString, NSNumber, and NSNull. Additionally, arrays and String-keyed dictionaries containing SerializedDataStorable values can call getData() (although it was not possible to define them as SerializedDataStorable).

You can extract these values back out using .string, .int, .float, .double, .nsNumber, .bool, .date (all optional values). You can test for nil with .isNil.

```swift

    var list = [String: SerializedDataStorable?]()
    list["var1"] = "String"
    list["var2"] = 5
    list["var3"] = 56.7
    list["var4"] = SerializableData.safeInit([1,2,3])
    let data = SerializableData.safeInit(list)
    print(data.serializedString)
    data["var1"]?.string == "String"
    data["var3"]?.double == 56.7
```

I did not bother to make SerializableData adhere to any of the collection protocols - if you want to interact with arrays or dictionaries, just pull their .array (type [SerializableData]?) or .dictionary (type [String: SerializableData]?) value and iterate through that.

```swift

    var data = SerializableData()
    data["myArray"] = [1,2,3]
    data["myDictionary"] = ["k1": "v1", "k2": "v2"]
    let optionalArray: [Int?] = (data["myArray"]?.array ?? []).map{ $0.int } 
    for (key, value) in (data["myDictionary"]?.dictionary ?? [:]) {
    	  print("\(key) = \(value.string)")
    }
}
```

There is also some support for CGFloat and URL, although they don't have XXXLiteralConvertible protocols, so you have to work a bit harder.

```swift

    var data = SerializableData()
    data["cgfloat"] = CGFloat(50).getData()
    data["url"] = URL(string: "http://www.example.com")?.getData()
    data["cgfloat"].cgFloat == CGFloat(50)
    data["url"].url == URL(string: "http://www.example.com")
}
```


I will probably add CGSize and CGPoint and CGRect eventually also, because I use those a lot and they are a pain to parse in and out of json.


## Creating Serializable Objects

Using the SerializedDataStorable and SerializedDataRetrievable protocols, you can set any object to be serializable, and easily nest them in your getData() and setData() calls. Because you have complete control over how data is serialized and extracted, you can customize it for strange data like tuples and locally-stored image urls.

```swift

	public struct MyStruct: SerializedDataStorable, SerializedDataRetrievable {
	    public var myProp1: String = "Test"
	    public var myDataSubClass: MyDataSubClass = MyDataSubClass(myNestedProp1: "Something")
	    public var myOptionalProp2: Int? = 5

	    public func getData() -> SerializableData {
	        var list = [String: SerializedDataStorable?]()
	        list["myProp1"] = myProp1
	        list["myOptionalProp2"] = myOptionalProp2
	        list["myDataSubClass"] = myDataSubClass
	        return SerializableData.safeInit(list)
	    }

	    public init() {}
	    
	    public init?(data: SerializableData?) {
	        guard let data = data, let myProp1 = data["myProp1"]?.string, 
                  let myDataSubClass = MyDataSubClass(data: data["myDataSubClass"])
	        else {
	            return nil
	        }
	        // required values:
	        self.myProp1 = myProp1
	        self.myDataSubClass = myDataSubClass
	        // optional values
	        myOptionalProp2 = data["myOptionalProp2"]?.int
	    }

	    public mutating func setData(data: SerializableData) {
            // you don't really have to use this function if you don't want, but with value types it is sometimes nice to be able to setData() instead of recreate the object with init?(), which would drop any observers you have attached to the object.
            // required values (specify fallback values to whatever you want)
	        myProp1 = data["myProp1"]?.string ?? myProp1
	        myDataSubClass = MyDataSubClass(data: data["myDataSubClass"]) ?? myDataSubClass
            // optional values
	        myOptionalProp2 = data["myOptionalProp2"]?.int
	    }
	}

	public class MyDataSubClass: SerializedDataStorable, SerializedDataRetrievable {
		public var myNestedProp1: String = "Test"
        
	    public func getData() -> SerializableData {
	        var list = [String: SerializedDataStorable?]()
	        list["myNestedProp1"] = myNestedProp1
	        return SerializableData.safeInit(list)
	    }
        
	    public init(myNestedProp1: String) {
	        self.myNestedProp1 = myNestedProp1
	    }
        
	    public required init?(data: SerializableData?) {
	        guard let data = data, 
                  let myNestedProp1 = data["myNestedProp1"]?.string
	        else {
	            return nil
	        }
	        // required values:
	        self.myNestedProp1 = myNestedProp1
	    }
        
	    public func setData(data: SerializableData) {}
        
	    // only required for class objects (sorry!):
	    public required convenience init?(serializedString json: String) throws {
	        self.init(data: try SerializableData(jsonString: json))
	    }
	}

	MyStruct().getData().serializedString
```


## Modifying SerializableData Data

When you create SerializableData data sets, you can get and set data pretty easily inside it, making it the perfect mechanism to bridge data between your app and web apis.

```swift

    var serializableData = SerializableData()
    serializableData["test1"] = "test"
    serializableData["number1"] = 5.01
    serializableData["bool1"] = true
    serializableData["date1"] = SerializableData.safeInit(date: NSDate()) // dates are tricky
    serializableData["array1"] = [1, 5]
    serializableData["dictionary1"] = ["key1": 1, "key2": 5]
    serializableData["dictionary1"]?["key1"] = 6
    serializableData["dictionary1"]?["key5"] = 10
```

## Modifying SerializableData Data

See the demo for examples saving and retrieving using both NSUserDefaults and CoreData.





