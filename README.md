# SerializableData

## 2017-08-15 Codable Conversion Project

This branch contains an example conversion from SerializableData to the new Codable protocol in Swift 4. Since SerializableData is designed to store data in JSON, this conversion is actually not that painful. In most cases, you don't have to provide the new encode() method and can entirely remove the prior getData() and setData() methods. You only need to supply init(from: Coder) if you want to use default values or transform values (yes: Codable child objects are extracted automatically by Codable).

### Quick breakdown on Codable serialization/deserialization:

```Swift
public struct Person: Codable {
    public var id: UUID
    public var name: String
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
    }
}
let sampleJson = """
        {
            "persons": [{
                "id": "\(UUID())",
                "name": "Phil Myman"
            }, {
                "id": "\(UUID())",
                "name": "Veronica Palmer"
            }]
        }
    """
let data = sampleJson.data(using: .utf8) ?? Data()
let list = (try? JSONDecoder().decode([String:[Person]].self, from: data)) ?? [:]
let persons = list["persons"] ?? []
let data2 = try JSONEncoder.encode(list)
```
