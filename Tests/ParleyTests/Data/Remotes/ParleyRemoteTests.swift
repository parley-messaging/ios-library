import Foundation
import XCTest
@testable import Parley

final class ParleyRemoteTests: XCTestCase {

    private var sut: ParleyRemote!
    private var parleyNetworkSessionSpy: ParleyNetworkSessionSpy!
    private var networkConfig: ParleyNetworkConfig!
    private var createSecretMock: (() -> String?)!
    private var createUniqueDeviceIdentifierMock: (() -> String?)!
    private var createUserAuthorizationTokenMock: (() -> String?)!
    private var mainQueueSpy: QueueSpy!
    private var backgroundQueueSpy: QueueSpy!

    override func setUpWithError() throws {
        parleyNetworkSessionSpy = ParleyNetworkSessionSpy()

        networkConfig = ParleyNetworkConfig(
            url: "https://api.parley.nu/",
            path: "/example",
            apiVersion: .v1_7
        )
        createSecretMock = { "secret" }
        createUniqueDeviceIdentifierMock = { "id" }
        createUserAuthorizationTokenMock = { "token" }
        mainQueueSpy = QueueSpy()
        backgroundQueueSpy = QueueSpy()
        sut = ParleyRemote(
            networkConfig: networkConfig,
            networkSession: parleyNetworkSessionSpy,
            createSecret: createSecretMock,
            createUniqueDeviceIdentifier: createUniqueDeviceIdentifierMock,
            createUserAuthorizationToken: createUserAuthorizationTokenMock,
            mainQueue: mainQueueSpy,
            backgroundQueue: backgroundQueueSpy
        )
    }

    override func tearDownWithError() throws {
        parleyNetworkSessionSpy = nil
        createSecretMock = nil
        networkConfig = nil
        createSecretMock = nil
        createUniqueDeviceIdentifierMock = nil
        mainQueueSpy = nil
        backgroundQueueSpy = nil
    }

    // MARK: - Execute request

    func testExecuteWithTypedResponseSuccess() throws {
        var onSuccessCalled = false
        var onFailureCalled = false

        sut.execute(
            .get,
            path: "path",
            keyPath: .none,
            onSuccess: { (items: [MediaResponse]) in
                XCTAssertEqual(items.count, 1)
                onSuccessCalled = true
            },
            onFailure: { _ in
                onFailureCalled = true
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callRequestCompletion(response: [MediaResponse(media: "test")])
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { self.parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
    }

    func testExecuteWithTypedResponseFailure() throws {
        var onSuccessCalled = false
        var onFailureCalled = false

        sut.execute(
            .get,
            path: "path",
            keyPath: .none,
            onSuccess: { (_: [MediaResponse]) in
                onSuccessCalled = true
            },
            onFailure: { _ in
                onFailureCalled = true
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callRequestCompletion(response: ["test"])
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { self.parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertFalse(onSuccessCalled)
        XCTAssertTrue(onFailureCalled)
    }

    func testExecuteWithNoTypedResponse() throws {
        var onSuccessCalled = false
        var onFailureCalled = false

        sut.execute(
            .post,
            path: "example/path",
            onSuccess: {
                onSuccessCalled = true
            },
            onFailure: { _ in
                onFailureCalled = true
            }
        )
        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callRequestCompletion(response: ["test"])
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { self.parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
    }

    func testExecuteWithMultipartFormData() throws {
        var onSuccessCalled = false
        var onFailureCalled = false
        var multipartFormDataCalled = false

        sut.execute(
            .post,
            path: "example/path",
            multipartFormData: { _ in
                multipartFormDataCalled = true
            },
            onSuccess: { (_: [MediaResponse]) in
                onSuccessCalled = true
            },
            onFailure: { error in
                onFailureCalled = true
                print(error)
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callUploadCompletion(response: ParleyResponse(data: [MediaResponse(media: "test")]))
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { self.parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
        XCTAssertTrue(multipartFormDataCalled)
    }

    func testExecuteWithImageData() throws {
        var resultCalled = false

        sut.execute(
            path: "media",
            data: Data(),
            name: "image",
            fileName: "image.jpg",
            type: .imageJPeg,
            result: { (_: Result<[MediaResponse], Error>) in
                resultCalled = true
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callUploadCompletion(response: ParleyResponse(data: [MediaResponse(media: "test")]))
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { self.parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(resultCalled)
    }

    // MARK: - MultipartFormData

    private func callRequestCompletion(response: Encodable) throws {
        let arguments = parleyNetworkSessionSpy.requestDataMethodHeadersCompletionReceivedArguments
        try arguments?.completion(.success(createResponse(body: CodableHelper.shared.encode(response))))
    }

    private func callUploadCompletion(response: Encodable) throws {
        let arguments = parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionReceivedArguments
        try arguments?.completion(.success(createResponse(body: CodableHelper.shared.encode(response))))
    }

    private func createResponse(
        body: Data = Data(),
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) -> ParleyHTTPDataResponse {
        ParleyHTTPDataResponse(body: body, statusCode: statusCode, headers: headers)
    }
}
