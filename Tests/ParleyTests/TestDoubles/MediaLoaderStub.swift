import Foundation
@testable import Parley

final class MediaLoaderStub: MediaLoaderProtocol {
    
    var loadResult: Data?
    var url: URL?
    var error: MediaLoader.MediaLoaderError = .deinitialized
    
    func load(media: MediaObject) async throws -> Data {
        if let loadResult {
            return loadResult
        } else {
            throw error
        }
    }
    
    func reset() async {
    }
}
