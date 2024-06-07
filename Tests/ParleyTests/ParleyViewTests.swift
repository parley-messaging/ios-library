import SnapshotTesting
import XCTest

@testable import Parley

final class ParleyViewTests: XCTestCase {
    override class func setUp() {
//        isRecording = true
    }

    private let secondsOfMinute = 60

    private let infoMessage = """
    **Welcome!**
    Want a quick answer to your question? Send your message directly. We can start directly as you are already identified. We are standing by for you every day between 8:00 and 22:00. You can safely close the app in the meantime, as you will receive a notification when we reply.
    """

    private let stickyMessage = """
    Due to high inquiry volumes, our response times may be longer than usual. We appreciate your patience and will get back to you as soon as possible. Thank you for your understanding.
    """

    func testEmptyParleyView() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(message: infoMessage, type: .info),
        ]

        let sut = ParleyView(
            parley: ParleyStub(
                messagesManager: messagesManagerStub,
                messageRepository: MessageRepositoryStub(),
                imageLoader: ImageLoaderStub(),
                localizationManager: ParleyLocalizationManager()
            ),
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testParleyView() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.stickyMessage = stickyMessage

        messagesManagerStub.messages = [
            Message.makeTestData(message: infoMessage, type: .info),
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
            Message.makeTestData(
                id: 2,
                time: Date(timeIntSince1970: 1 * secondsOfMinute),
                title: nil,
                message: "We will look into that!",
                type: .agent
            ),
            Message.makeTestData(
                id: 3,
                time: Date(timeIntSince1970: 2 * secondsOfMinute),
                title: nil,
                message: "Thank you for your **prompt** *reply* ❤️",
                type: .user,
                status: .pending,
                agent: nil
            ),
            Message.makeTestData(type: .agentTyping),
        ]

        let sut = ParleyView(
            parley: ParleyStub(
                messagesManager: messagesManagerStub,
                messageRepository: MessageRepositoryStub(),
                imageLoader: ImageLoaderStub(),
                localizationManager: ParleyLocalizationManager()
            ),
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testMessageWithImage() throws {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                media: MediaObject(id: "mediaObject"),
                type: .user,
                agent: nil
            ),
        ]

        let imageLoaderStub = ImageLoaderStub()
        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))
        imageLoaderStub.loadResult = model

        let sut = ParleyView(
            parley: ParleyStub(
                messagesManager: messagesManagerStub,
                messageRepository: MessageRepositoryStub(),
                imageLoader: imageLoaderStub,
                localizationManager: ParleyLocalizationManager()
            ),
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)

        wait()

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testMessageWithCarousel() throws {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                carousel: [
                    Message.makeTestData(
                        id: 2,
                        time: Date(timeIntSince1970: 2),
                        title: nil,
                        message: "Carousel 1",
                        media: MediaObject(id: "id"),
                        type: .user,
                        agent: nil
                    ),
                    Message.makeTestData(
                        id: 3,
                        time: Date(timeIntSince1970: 4),
                        title: nil,
                        message: "Carousel 2",
                        type: .user,
                        agent: nil
                    ),
                ],
                type: .user,
                agent: nil
            ),
            Message.makeTestData(type: .agentTyping),
        ]

        let imageLoaderStub = ImageLoaderStub()
        let image = try XCTUnwrap(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try XCTUnwrap(image.pngData())
        let model = try XCTUnwrap(ImageDisplayModel(data: data, type: .png))
        imageLoaderStub.loadResult = model

        let sut = ParleyView(
            parley: ParleyStub(
                messagesManager: messagesManagerStub,
                messageRepository: MessageRepositoryStub(),
                imageLoader: imageLoaderStub,
                localizationManager: ParleyLocalizationManager()
            ),
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)

        wait()

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testOfflineView() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        parleyStub.reachable = false

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.unreachable()
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testPushDisabled() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        parleyStub.pushEnabled = false

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testUnConfiguredState() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.unconfigured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testConfiguringState() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configuring)

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testFailedState() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = [
            Message.makeTestData(time: Date(timeIntSince1970: 1), type: .date),
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.failed)

        applySize(sut: sut)

        assert(sut: sut)
    }

    func testConfiguredStateWithNoMessages() {
        let messagesManagerStub = MessagesManagerStub()

        messagesManagerStub.messages = []

        let parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
        )

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        sut.reachable()
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    private func applySize(sut: UIView) {
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true
        sut.heightAnchor.constraint(equalToConstant: 600).isActive = true
    }

    private func assert(
        sut: UIView,
        traits: UITraitCollection = UITraitCollection(),
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            matching: sut,
            as: .image(traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}
