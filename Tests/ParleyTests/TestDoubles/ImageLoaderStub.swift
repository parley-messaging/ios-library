@testable import Parley

final class ImageLoaderStub: ImageLoaderProtocol {
    var loadResult: ImageDisplayModel?
    var error: ImageLoader.ImageLoaderError = .deinitialized

    func load(id: String) async throws -> ImageDisplayModel {
        if let loadResult {
            return loadResult
        } else {
            throw error
        }
    }

    func reset() async {
    }
}
