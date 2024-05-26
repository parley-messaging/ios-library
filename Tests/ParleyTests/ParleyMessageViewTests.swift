import SnapshotTesting
import XCTest

@testable import Parley

final class ParleyMessageViewTests: XCTestCase {

    func testDefaultAgentMessageView() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.agent()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, type: .agent),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testDefaultUserMessageView() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testDefaultUserMessageViewWithShortMessage() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: "Lo", agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testDefaultUserMessageViewPendingStatus() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: "Lo", status: .pending, agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testDefaultUserMessageViewFailedStatus() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: "Lo", status: .failed, agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testCustomBalloonImageUser() {
        let sut = makeSut()

        let appearance = MessageCollectionViewCellAppearance.user()

        appearance.balloonImage = UIImage(named: "chat_bubble_user", in: .module, compatibleWith: nil)?
            .resizableImage(withCapInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        appearance.balloonTintColor = .lightGray

        sut.appearance = appearance

        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testWithBiggerFontSizeAgent() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.agent()

        sut.set(
            message: .makeTestData(message: Self.dummyMessageText),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithBiggerFontSizeUser() {
        let sut = makeSut()

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithLoadingImage() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = makeSut(imageLoader: imageLoader)

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, media: MediaObject(id: "identifier"), agent: nil),
            forcedTime: Self.dummyDate
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testWithImageResult() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = makeSut(imageLoader: imageLoader)

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, media: MediaObject(id: "identifier"), agent: nil),
            forcedTime: Self.dummyDate
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    func testWithImageErrorResult() throws {
        let imageLoader = ImageLoaderStub()
        imageLoader.error = .unableToConvertImageData

        let sut = makeSut(imageLoader: imageLoader)

        sut.appearance = MessageCollectionViewCellAppearance.user()
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, media: MediaObject(id: "identifier"), agent: nil),
            forcedTime: Self.dummyDate
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
    }

    private func makeSut(imageLoader: ImageLoaderStub = ImageLoaderStub()) -> ParleyMessageView {
        ParleyMessageView(frame: .zero, imageLoader: imageLoader)
    }

    private func addToContainer(sut: UIView, width: CGFloat = 320) -> UIView {
        let container = UIView()
        container.addSubview(sut)

        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: width).isActive = true

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        sut.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        sut.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor).isActive = true
        sut.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        return container
    }

    private func assert(
        sut: UIView,
        traits: UITraitCollection = UITraitCollection(),
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(matching: sut, as: .image(traits: traits), file: file, testName: testName, line: line)
    }

    private static let dummyDate = Date(timeIntervalSince1970: 0)
    private static let dummyMessageText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
}
