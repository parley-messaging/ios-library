import Foundation
@testable import Parley

final class MediaLoaderStub: MediaLoaderProtocol {
    
    var loadResult: MediaDisplayModel?
    var url: URL?
    var error: MediaLoader.MediaLoaderError = .deinitialized
    
    func load(media: MediaObject) async throws -> MediaDisplayModel {
        if let loadResult {
            return loadResult
        } else {
            throw error
        }
    }
    
    func share(media: MediaObject) async throws -> URL {
        if let url {
            return url
        } else {
            throw error
        }
    }
    
    func reset() async {
    }
}
