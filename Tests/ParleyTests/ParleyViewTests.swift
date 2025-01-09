import SnapshotTesting
import Testing
import UIKit
@testable import Parley

@Suite("Parley View Tests", .tags(.userInterface), .serialized)
@MainActor
struct ParleyViewTests {

    private let secondsOfMinute = 60
    private var sut: ParleyView!
    private let messagesManagerStub: MessagesManagerStub
    private var interactor: MessagesInteractor!
    private var parleyStub: ParleyStub!
    
    init() {
        messagesManagerStub = MessagesManagerStub()
    }
    
    private mutating func setup(
        mediaLoader: MediaLoaderStub? = nil
    ) {
        let mediaLoader = mediaLoader ?? MediaLoaderStub()
        let localizationManager = ParleyLocalizationManager()
        let notificationServiceStub = NotificationServiceStub()
        let pollingServiceStub = PollingServiceStub()
        let messageRepositoryStub = MessageRepositoryStub()
        let reachabilityProvideStub = ReachibilityProviderStub()
        let messagesStore = MessagesStore()
        let messagePresenter = MessagesPresenter(store: messagesStore, display: nil)
        
        interactor = MessagesInteractor(
            presenter: messagePresenter,
            messagesManager: messagesManagerStub,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .current),
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: reachabilityProvideStub
        )
        
        parleyStub = ParleyStub(
            messagesManager: messagesManagerStub,
            messageRepository: messageRepositoryStub,
            mediaLoader: mediaLoader,
            localizationManager: localizationManager,
            messagesInteractor: interactor,
            messagesPresenter: messagePresenter,
            messagesStore: messagesStore
        )
        
        sut = ParleyView(
            parley: parleyStub,
            pollingService: pollingServiceStub,
            notificationService: notificationServiceStub
        )
        
        messagePresenter.set(display: sut)
    }

    private let infoMessage = """
    **Welcome!**
    Want a quick answer to your question? Send your message directly. We can start directly as you are already identified. We are standing by for you every day between 8:00 and 22:00. You can safely close the app in the meantime, as you will receive a notification when we reply.
    """

    private let stickyMessage = """
    Due to high inquiry volumes, our response times may be longer than usual. We appreciate your patience and will get back to you as soon as possible. Thank you for your understanding.
    """

    @Test
    mutating func testEmptyParleyView() {
        messagesManagerStub.messages = []
        messagesManagerStub.welcomeMessage = infoMessage
        
        setup()
        
        sut.reachable()
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testParleyView() {
        messagesManagerStub.stickyMessage = stickyMessage
        messagesManagerStub.welcomeMessage = infoMessage
        
        messagesManagerStub.messages = [
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
            )
        ]
        
        setup()

        sut.reachable()
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)
        
        interactor.handleAgentBeganTyping()
        
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testMessageWithImage() async throws {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                media: MediaObject(id: "mediaObject", mimeType: "image/png"),
                type: .user,
                agent: nil
            ),
        ]

        let mediaLoaderStub = MediaLoaderStub()
        let image = try #require(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try #require(image.pngData())
        mediaLoaderStub.loadResult = data
        
        setup(mediaLoader: mediaLoaderStub)

        sut.reachable()
        sut.didChangeState(.configured)

        try await wait(milliseconds: 500)

        applySize(sut: sut)
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .default))
    mutating func testMessageWithCarousel() async throws {
        messagesManagerStub.messages = [
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
                        media: MediaObject(id: "id", mimeType: "image/png"),
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
            )
        ]

        let mediaLoaderStub = MediaLoaderStub()
        let image = try #require(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try #require(image.pngData())
        mediaLoaderStub.loadResult = data
        
        setup(mediaLoader: mediaLoaderStub)
        
        sut.reachable()
        sut.didChangeState(.configured)
        
        try await wait(milliseconds: 30)
        
        applySize(sut: sut)
        
        interactor.handleAgentBeganTyping()
        
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testAgentTypingIndicatorAppearance() {
        messagesManagerStub.stickyMessage = stickyMessage
        messagesManagerStub.messages = []
        
        setup()
        
        sut.appearance.typingBalloon.dots = .init(
            color: .systemRed,
            spacing: 10,
            size: 20,
            transparency: (min: 0.5, max: 0.9),
            animationCurve: .easeInOut,
            animationScaleFactor: 1.2,
            animationInterval: 0.9
        )

        sut.reachable()
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)
        interactor.handleAgentBeganTyping()

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testOfflineView() {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        setup()
        
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
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testPushDisabled() {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ]
        
        setup()

        parleyStub.pushEnabled = false

        sut.reachable()
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testUnConfiguredState() {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ]
        
        setup()

        sut.reachable()
        sut.didChangeState(.unconfigured)

        applySize(sut: sut)

        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    func testUnConfiguredStateOfNonStubbedParleyView() {
        let sut = ParleyView()
        applySize(sut: sut)
        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testConfiguringState() {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ]
        
        setup()

        sut.reachable()
        sut.didChangeState(.configuring)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testFailedState() {
        messagesManagerStub.messages = [
            Message.makeTestData(
                id: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ]

        setup()

        sut.reachable()
        sut.didChangeState(.failed)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testConfiguredStateWithNoMessages() {
        messagesManagerStub.messages = []
        setup()

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
            of: sut,
            as: .image(traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
    
    private func wait(milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}
