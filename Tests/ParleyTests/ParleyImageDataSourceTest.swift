import XCTest
@testable import Parley

final class ParleyImageDataSourceTest: XCTestCase {
    
    private var testImage: UIImage {
        UIImage(resource: .Tests.redBlockJpg)
    }
    
    private var testImageData: Data? {
        testImage.jpegData(compressionQuality: 1)
    }
    
    private lazy var dataSource: ParleyImageDataSource = {
        return try! ParleyEncryptedImageDataSource(key: "6543210987654321")
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
        
        let localImage = ParleyStoredImage(id: UUID().uuidString, data: imageData, type: .jpg)
        dataSource.save(image: localImage)
        
        guard let fetchedImage = dataSource.image(id: localImage.id) else {
            XCTFail("Should exist") ; return
        }
        
        XCTAssertEqual(fetchedImage, localImage)
        
        let allImages = dataSource.all()
        XCTAssertEqual(allImages.count, 1)
        XCTAssertTrue(allImages.contains(localImage))
    }
    
    func testDataSource_shouldSaveArrayOfImages() {
        let images = [
            ParleyStoredImage(
                id: UUID().uuidString,
                data: UIImage(resource: .Tests.blueGradientPng).pngData()!,
                type: .png
            ),
            ParleyStoredImage(
                id: UUID().uuidString,
                data: UIImage(resource: .Tests.redBlockJpg).jpegData(compressionQuality: 1)!,
                type: .jpg
            ),
        ]
        
        dataSource.save(images: images)
        
        let fetchedImage = dataSource.all()
        XCTAssertEqual(images.count, fetchedImage.count)
    }
    
    func testDataSource_shouldDeleteImage_AfterSavingImage() throws {
        let imageData = testImageData!
        let localImage = ParleyStoredImage(id: UUID().uuidString, data: imageData, type: .jpg)
        dataSource.save(image: localImage)
        
        XCTAssertTrue(dataSource.delete(id: localImage.id))
        
        XCTAssertNil(dataSource.image(id: localImage.id))
        
        XCTAssertFalse(dataSource.delete(id: localImage.id), "Should not find image, which should return `false`.")
    }
}
