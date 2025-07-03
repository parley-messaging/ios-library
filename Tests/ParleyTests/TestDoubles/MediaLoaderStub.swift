import Foundation
@testable import Parley

actor MediaLoaderStub: MediaLoaderProtocol {

    private(set) var loadResult: Data?
    private(set) var url: URL?
    private(set) var error: MediaLoader.MediaLoaderError = .deinitialized

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

extension MediaLoaderStub {
    
    func setLoadResult(_ data: Data?) {
        self.loadResult = data
    }
    
    func set(url: URL?) {
        self.url = url
    }
    
    func set(error: MediaLoader.MediaLoaderError) {
        self.error = error
    }
}
