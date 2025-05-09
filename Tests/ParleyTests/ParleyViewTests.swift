@testable import Parley
import SnapshotTesting
import Testing
import UIKit

@Suite("Parley View Tests", .serialized, .tags(.userInterface))
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
    ) async {
        let mediaLoader = mediaLoader ?? MediaLoaderStub()
        let localizationManager = ParleyLocalizationManager()
        let notificationServiceStub = NotificationServiceStub()
        let pollingServiceStub = PollingServiceStub()
        let messageRepositoryStub = MessageRepositoryStub()
        let reachabilityProvideStub = ReachabilityProviderStub()
        let messagesStore = MessagesStore()
        let messagePresenter = MessagesPresenter(store: messagesStore, display: nil)
        
        interactor = await MessagesInteractor(
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
        
        sut = await ParleyView(
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

    @Test(.snapshots(diffTool: .compareSideBySide))
    @MainActor
    mutating func testEmptyParleyView() async {
        await messagesManagerStub.setMessages([])
        await messagesManagerStub.setWelcomeMessage(infoMessage)
        
        await setup()
        let isPushEnabled = await parleyStub.pushEnabled
        
        sut.reachable(pushEnabled: isPushEnabled)
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center
        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test
    mutating func testParleyView() async {
        await messagesManagerStub.setStickyMessage(stickyMessage)
        await messagesManagerStub.setWelcomeMessage(infoMessage)
        
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
            Message.makeTestData(
                remoteId: 2,
                time: Date(timeIntSince1970: 1 * secondsOfMinute),
                title: nil,
                message: "We will look into that!",
                type: .agent
            ),
            Message.makeTestData(
                remoteId: 3,
                time: Date(timeIntSince1970: 2 * secondsOfMinute),
                title: nil,
                message: "Thank you for your **prompt** *reply* ❤️",
                type: .user,
                status: .pending,
                agent: nil
            )
        ])
        
        await setup()

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)
        
        await interactor.handleAgentBeganTyping()
        
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    @MainActor
    mutating func testMessageWithImage() async throws {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                media: MediaObject(id: "mediaObject", mimeType: "image/png"),
                type: .user,
                agent: nil
            ),
        ])

        let mediaLoaderStub = MediaLoaderStub()
        let image = try #require(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try #require(image.pngData())
        await mediaLoaderStub.setLoadResult(data)
        
        await setup(mediaLoader: mediaLoaderStub)

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configured)
        
        applySize(sut: sut)
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .default))
    mutating func testMessageWithCarousel() async throws {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                carousel: [
                    Message.makeTestData(
                        remoteId: 2,
                        time: Date(timeIntSince1970: 2),
                        title: nil,
                        message: "Carousel 1",
                        media: MediaObject(id: "id", mimeType: "image/png"),
                        type: .user,
                        agent: nil
                    ),
                    Message.makeTestData(
                        remoteId: 3,
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
        ])

        let mediaLoaderStub = MediaLoaderStub()
        let image = try #require(UIImage(named: "Parley", in: .module, compatibleWith: nil))
        let data = try #require(image.pngData())
        await mediaLoaderStub.setLoadResult(data)
        
        await setup(mediaLoader: mediaLoaderStub)
        
        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configured)
        
        try await wait(milliseconds: 30)
        
        applySize(sut: sut)
        
        await interactor.handleAgentBeganTyping()
        
        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testAgentTypingIndicatorAppearance() async {
        await messagesManagerStub.setStickyMessage(stickyMessage)
        await messagesManagerStub.setMessages([])
        
        await setup()
        
        sut.appearance.typingBalloon.dots = .init(
            color: .systemRed,
            spacing: 10,
            size: 20,
            transparency: (min: 0.5, max: 0.9),
            animationCurve: .easeInOut,
            animationScaleFactor: 1.2,
            animationInterval: 0.9
        )

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configured)
        sut.appearance.info.textViewAppearance.paragraphStyle.alignment = .center

        applySize(sut: sut)
        await interactor.handleAgentBeganTyping()

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testOfflineView() async {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ])

        await setup()
        
        await parleyStub.set(reachable: false)

        let sut = await ParleyView(
            parley: parleyStub,
            pollingService: PollingServiceStub(),
            notificationService: NotificationServiceStub()
        )

        await sut.unreachable(isCachingEnabled: parleyStub.isCachingEnabled())
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testPushDisabled() async {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ])
        
        await setup()

        await parleyStub.set(pushEnabled: false)

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configured)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testUnConfiguredState() async {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ])
        
        await setup()

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.unconfigured)

        applySize(sut: sut)

        assert(sut: sut)
    }
    
    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testUnConfiguredStateOfNonStubbedParleyView() async throws {
        let sut = ParleyView()
        sut.didChangePushEnabled(true)
        applySize(sut: sut)
        try await wait(milliseconds: 50)
        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testConfiguringState() async {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            )
        ])
        
        await setup()

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.configuring)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testFailedState() async {
        await messagesManagerStub.setMessages([
            Message.makeTestData(
                remoteId: 1,
                time: Date(timeIntSince1970: 1),
                title: nil,
                message: "This is my question.",
                type: .user,
                agent: nil
            ),
        ])

        await setup()

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
        sut.didChangeState(.failed)

        applySize(sut: sut)

        assert(sut: sut)
    }

    @Test(.snapshots(diffTool: .compareSideBySide))
    mutating func testConfiguredStateWithNoMessages() async {
        await messagesManagerStub.setMessages([])
        await setup()

        await sut.reachable(pushEnabled: parleyStub.pushEnabled)
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
        file: StaticString = #filePath,
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
