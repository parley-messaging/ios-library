import UIKit
import Testing
@testable import Parley

@Suite("Parley Imgage Data Source Tests")
struct ParleyImageDataSourceTests {

    private let testImage: UIImage = UIImage(resource: .Tests.redBlockJpg)

    private var testImageData: Data? {
        testImage.jpegData(compressionQuality: 1)
    }

    private let dataSource: ParleyMediaDataSource
    
    init() throws {
        let crypter = try ParleyCrypter(key: "6543210987654321", size: .bits128)
        dataSource = try ParleyEncryptedMediaDataSource(
            crypter: crypter,
            directory: .custom("parley_images_tests_\(UUID().uuidString)")
        )
    }

    @Test
    func testDataSource_ShouldBeEmpty_OnCreation() async {
        await #expect(dataSource.all().isEmpty, "Datasource should be empty")
    }

    @Test
    func testDataSource_ShouldClear_withNoData() async {
        let didClear = await dataSource.clear()
        #expect(didClear, "Datasource should clear")
        await #expect(dataSource.all().isEmpty, "Datasource should still be empty")
    }

    @Test
    func testDataSource_ShouldSaveImage_whenAttemptingToSaveJPEG() async throws {
        let imageData = try #require(testImage.jpegData(compressionQuality: 1))
        
        let localImage = ParleyStoredMedia(filename: UUID().uuidString, data: imageData, type: .imageJPeg)
        await dataSource.save(media: localImage)

        let fetchedImage = try #require(await dataSource.media(id: localImage.id))

        #expect(fetchedImage == localImage)

        let allImages = await dataSource.all()
        #expect(allImages.count == 1)
        #expect(allImages.contains(localImage))
    }

    @Test
    func testDataSource_shouldSaveArrayOfImages() async {
        let media = [
            ParleyStoredMedia(
                filename: UUID().uuidString,
                data: UIImage(resource: .Tests.blueGradientPng).pngData()!,
                type: .imagePng
            ),
            ParleyStoredMedia(
                filename: UUID().uuidString,
                data: UIImage(resource: .Tests.redBlockJpg).jpegData(compressionQuality: 1)!,
                type: .imageJPeg
            ),
        ]

        await dataSource.save(media: media)

        let fetchedImage = await dataSource.all()
        #expect(media.count == fetchedImage.count)
    }

    @Test
    func testDataSource_shouldDeleteMedia_AfterSavingMedia() async throws {
        let imageData = try #require(testImageData)
        let localImage = ParleyStoredMedia(filename: UUID().uuidString, data: imageData, type: .imageJPeg)
        await dataSource.save(media: localImage)

        #expect(await dataSource.delete(id: localImage.id))

        await #expect(dataSource.media(id: localImage.id) == nil)

        await #expect(dataSource.delete(id: localImage.id) == false, "Should not find image, which should return `false`.")
    }
}
