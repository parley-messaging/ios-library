import Foundation
@testable import Parley

final class ShareManagerStub: ShareManagerProtocol {
    
    var url: URL?
    var error: ShareManager.ShareManagerError = .unableToSaveFile(id: "Test")
    
    func share(media: MediaObject) async throws -> URL {
        if let url {
            return url
        } else {
            throw error
        }
    }
}
