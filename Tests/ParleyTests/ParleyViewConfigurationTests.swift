import XCTest
@testable import Parley

final class ParleyViewConfigurationTests: XCTestCase {
    
    func testPollingServiceIsRenewedWhenStateBecomesUnconfigured() {
        
        let messagesManager = MessagesManagerStub()
        let messageRepositoryStub = MessageRepositoryStub()
        let reachabilityProvideStub = ReachabilityProviderStub()
        
        let messagesStore = MessagesStore()
        let messagePresenter = MessagesPresenter(store: messagesStore, display: nil)
        let messagesInteractor = MessagesInteractor(
            presenter: messagePresenter,
            messagesManager: messagesManager,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .current),
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: reachabilityProvideStub
        )
        
        let parleyStub = ParleyStub(
            messagesManager: messagesManager,
            messageRepository: messageRepositoryStub,
            mediaLoader: MediaLoaderStub(),
            localizationManager: ParleyLocalizationManager(),
            messagesInteractor: messagesInteractor,
            messagesPresenter: messagePresenter,
            messagesStore: messagesStore
        )

        let pollingServiceStub = PollingServiceStub()

        let sut = ParleyView(
            parley: parleyStub,
            pollingService: pollingServiceStub,
            notificationService: NotificationServiceStub()
        )

        XCTAssertTrue(sut.pollingService === pollingServiceStub)

        parleyStub.state = .configured

        let newlyInstantiatedSut = ParleyView(
            parley: parleyStub,
            pollingService: nil,
            notificationService: NotificationServiceStub()
        )

        XCTAssertNotNil(newlyInstantiatedSut.pollingService)

        parleyStub.messagesManager = nil
        newlyInstantiatedSut.didChangeState(.unconfigured)

        XCTAssertNil(newlyInstantiatedSut.pollingService)

        parleyStub.messagesManager = MessagesManagerStub()
        newlyInstantiatedSut.didChangeState(.configured)

        XCTAssertNotNil(newlyInstantiatedSut.pollingService)
        XCTAssertFalse(newlyInstantiatedSut.pollingService === pollingServiceStub)
    }
}
