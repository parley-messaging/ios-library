import Testing
@testable import Parley

@Suite("ParleyViewConfigurationTests", .tags(.userInterface))
struct ParleyViewConfigurationTests {
    
    @MainActor
    @Test(.tags(.userInterface))
    func testPollingServiceIsRenewedWhenStateBecomesUnconfigured() async {
        
        let messagesManager = MessagesManagerStub()
        let messageRepositoryStub = MessageRepositoryStub()
        let reachabilityProvideStub = ReachabilityProviderStub()
        
        let messagesStore = MessagesStore()
        let messagePresenter = MessagesPresenter(store: messagesStore, display: nil)
        let messagesInteractor = await MessagesInteractor(
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

        let sut = await ParleyView(
            parley: parleyStub,
            pollingService: pollingServiceStub,
            notificationService: NotificationServiceStub()
        )
        
        await MainActor.run {
            #expect(sut.pollingService === pollingServiceStub)
        }
        
        await parleyStub.set(state: .configured)
        
        let newlyInstantiatedSut = await ParleyView(
            parley: parleyStub,
            pollingService: nil,
            notificationService: NotificationServiceStub()
        )
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService != nil)
        }
        
        await parleyStub.set(messagesManager: nil)
        newlyInstantiatedSut.didChangeState(.unconfigured)
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService == nil)
        }
        
        await parleyStub.set(messagesManager: MessagesManagerStub())
        newlyInstantiatedSut.didChangeState(.configured)
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService != nil)
            #expect(newlyInstantiatedSut.pollingService !== pollingServiceStub)
        }
    }
}
