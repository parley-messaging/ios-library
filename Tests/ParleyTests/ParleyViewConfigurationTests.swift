import XCTest
@testable import Parley

final class ParleyViewConfigurationTests: XCTestCase {
    func testPollingServiceIsRenewedWhenStateBecomesUnconfigured() {
        let parleyStub = ParleyStub(
            messagesManager: MessagesManagerStub(),
            messageRepository: MessageRepositoryStub(),
            imageLoader: ImageLoaderStub(),
            localizationManager: ParleyLocalizationManager()
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
