import Testing
@testable import Parley

@Suite("ParleyViewConfigurationTests")
struct ParleyViewConfigurationTests {
    
    func testPollingServiceIsRenewedWhenStateBecomesUnconfigured() async {
        
        let messagesManager = MessagesManagerStub()
        let messageRepositoryStub = MessageRepositoryStub()
        let reachabilityProvideStub = ReachabilityProviderStub()
        
        let messagesStore = await MessagesStore()
        let messagePresenter = await MessagesPresenter(store: messagesStore, display: nil)
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
        
        let pollingServiceStub = await PollingServiceStub()
        
        let sut = await ParleyView(
            parley: parleyStub,
            pollingService: nil,
            notificationService: NotificationServiceStub()
        )
        await MainActor.run {
            #expect(sut.pollingService === pollingServiceStub)
        }
        
        await parleyStub.set(state: .configured)
        
        let newlyInstantiatedSut: ParleyView = await ParleyView(
            parley: parleyStub,
            pollingService: nil,
            notificationService: NotificationServiceStub()
        )
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService != nil)
        }
        
        await parleyStub.set(messagesManager: nil)
        await newlyInstantiatedSut.didChangeState(.unconfigured)
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService == nil)
        }
        
        await parleyStub.set(messagesManager: MessagesManagerStub())
        await newlyInstantiatedSut.didChangeState(.configured)
        
        await MainActor.run {
            #expect(newlyInstantiatedSut.pollingService != nil)
            #expect(newlyInstantiatedSut.pollingService !== pollingServiceStub)
        }
    }
}
