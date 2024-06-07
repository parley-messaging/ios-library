import SnapshotTesting
import XCTest

@testable import Parley

final class ParleyMessageViewTests: XCTestCase {

    func testDefaultAgentMessageView() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(message: Self.dummyMessageText, type: .agent),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testDefaultUserMessageView() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(title: nil, message: Self.dummyMessageText, agent: nil),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testDefaultUserMessageViewWithShortMessage() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(title: nil, message: "Lo", agent: nil),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testDefaultAgentMessageViewWithShortMessage() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(message: "Lo"),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testDefaultUserMessageViewPendingStatus() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(title: nil, message: "Lo", status: .pending, agent: nil),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testDefaultUserMessageViewFailedStatus() {
        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(title: nil, message: "Lo", status: .failed, agent: nil),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testCustomBalloonImageUser() {
        let sut = ParleyMessageView()

        let appearance = MessageCollectionViewCellAppearance.user()

        let edgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        appearance.balloonImage = UIImage(named: "chat_bubble_user", in: .module, compatibleWith: nil)?
            .resizableImage(withCapInsets: edgeInsets)
        appearance.balloonTintColor = .lightGray

        sut.apply(appearance)

        sut.set(
            message: .makeTestData(title: nil, message: Self.dummyMessageText, agent: nil),
            forcedTime: Self.dummyDate,
            imageLoader: nil
        )

        let container = addToContainer(sut: sut)
        container.layoutIfNeeded() // Without this, balloon left-bottom corner goes incorrect
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithLoadingImageForUser() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(
                title: nil,
                message: Self.dummyMessageText,
                media: MediaObject(id: "identifier"),
                agent: nil
            ),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithImageResultForUser() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(
                title: nil,
                message: Self.dummyMessageText,
                media: MediaObject(id: "identifier"),
                agent: nil
            ),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithImageErrorResultForUser() throws {
        let imageLoader = ImageLoaderStub()
        imageLoader.error = .unableToConvertImageData

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.user())
        sut.set(
            message: .makeTestData(
                title: nil,
                message: Self.dummyMessageText,
                media: MediaObject(id: "identifier"),
                agent: nil
            ),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithLoadingImageForAgentWithoutTitleAndMessage() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(title: nil, message: nil, media: MediaObject(id: "identifier")),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithImageResultForAgentWithoutTitleAndMessage() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(title: nil, message: nil, media: MediaObject(id: "identifier")),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithImageErrorResultForAgentWithoutTitleAndMessage() throws {
        let imageLoader = ImageLoaderStub()
        imageLoader.error = .unableToConvertImageData

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(title: nil, message: nil, media: MediaObject(id: "identifier")),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
    }

    func testWithWhiteImageResultForAgentWithoutTitleAndMessage() throws {
        let imageLoader = ImageLoaderStub()

        let image = try XCTUnwrap(UIImage(named: "white_image", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))

        imageLoader.loadResult = model

        let sut = ParleyMessageView()

        sut.apply(MessageCollectionViewCellAppearance.agent())
        sut.set(
            message: .makeTestData(
                title: nil,
                message: nil,
                media: MediaObject(id: "identifier"),
                agent: Agent(id: 1, name: "Longer Agent Name", avatar: nil)
            ),
            forcedTime: Self.dummyDate,
            imageLoader: imageLoader
        )

        wait()

        let container = addToContainer(sut: sut)
        assert(sut: container)
        assert(
            sut: container,
            traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
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
