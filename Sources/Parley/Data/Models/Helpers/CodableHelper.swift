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

    func encode<T>(_ value: T) throws -> Data where T: Encodable {
        try encoder.encode(value)
    }

    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try decoder.decode(type, from: data)
    }

}
