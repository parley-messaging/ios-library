import XCTest
@testable import Parley

final class ParleyImageDataSourceTests: XCTestCase {

    private var testImage: UIImage {
        UIImage(resource: .Tests.redBlockJpg)
    }

    private var testImageData: Data? {
        testImage.jpegData(compressionQuality: 1)
    }

    private lazy var dataSource: ParleyMediaDataSource = {
        let crypter = try! ParleyCrypter(key: "6543210987654321", size: .bits128)
        return try! ParleyEncryptedMediaDataSource(crypter: crypter, directory: .custom("parley_images_tests"))
    }()

    override func setUp() {
        dataSource.clear()
    }

    func testDataSource_ShouldBeEmpty_OnCreation() {
        XCTAssertTrue(dataSource.all().isEmpty, "Datasource should be empty")
    }

    func testDataSource_ShouldClear_withNoData() {
        let didClear = dataSource.clear()
        XCTAssertTrue(didClear, "Datasource should clear")
        XCTAssertTrue(dataSource.all().isEmpty, "Datasource should still be empty")
    }

    func testDataSource_ShouldSaveImage_whenAttemptingToSaveJPEG() {
        guard let imageData = testImage.jpegData(compressionQuality: 1) else {
            XCTFail("Should exist") ; return
        }

        let localImage = ParleyStoredMedia(filename: UUID().uuidString, data: imageData, type: .imageJPeg)
        dataSource.save(media: localImage)

        guard let fetchedImage = dataSource.media(id: localImage.id) else {
            XCTFail("Should exist") ; return
        }

        XCTAssertEqual(fetchedImage, localImage)

        let allImages = dataSource.all()
        XCTAssertEqual(allImages.count, 1)
        XCTAssertTrue(allImages.contains(localImage))
    }

    func testDataSource_shouldSaveArrayOfImages() {
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

        dataSource.save(media: media)

        let fetchedImage = dataSource.all()
        XCTAssertEqual(media.count, fetchedImage.count)
    }

    func testDataSource_shouldDeleteMedia_AfterSavingMedia() throws {
        let imageData = testImageData!
        let localImage = ParleyStoredMedia(filename: UUID().uuidString, data: imageData, type: .imageJPeg)
        dataSource.save(media: localImage)

        XCTAssertTrue(dataSource.delete(id: localImage.id))

        XCTAssertNil(dataSource.media(id: localImage.id))

        XCTAssertFalse(dataSource.delete(id: localImage.id), "Should not find image, which should return `false`.")
    }
}
