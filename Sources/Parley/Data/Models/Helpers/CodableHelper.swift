import Foundation

struct CodableHelper {

    static let shared = CodableHelper(decoder: JSONDecoder(), encoder: JSONEncoder())

    init(decoder: JSONDecoder, encoder: JSONEncoder) {
        self.decoder = decoder
        self.encoder = encoder
    }

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    func toJSONString(_ object: Encodable) throws -> String {
        let data = try encode(object)
        let result = String(decoding: data, as: UTF8.self)
        return result
    }

    /// Converting object to post-able dictionary
    func toDictionary<T>(_ value: T) throws -> [String: Any] where T: Encodable {
        let data = try encoder.encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            let context = DecodingError.Context(
                codingPath: [],
                debugDescription: "Deserialized object is not a dictionary"
            )
            throw DecodingError.typeMismatch(type(of: object), context)
        }
        return json
    }

    func encode<T>(_ value: T) throws -> Data where T: Encodable {
        try encoder.encode(value)
    }

    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try decoder.decode(type, from: data)
    }

}
