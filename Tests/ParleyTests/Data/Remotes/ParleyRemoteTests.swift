import Foundation
import XCTest
@testable import Parley

final class ParleyRemoteTests: XCTestCase {

    private var sut: ParleyRemote!

    override func setUpWithError() throws {
        sut = makeSut()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Execute request

    func testExecuteWithTypedResponseSuccess() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

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
        try callRequestCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: [MediaResponse(media: "test")]
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
    }

    func testExecuteWithTypedResponseFailureWhenSecretIsNotSet() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil },
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

        var onSuccessCalled = false
        var onFailureCalled = false
        var onFailureError: Error? = nil

        sut.execute(
            .get,
            path: "path",
            keyPath: .none,
            onSuccess: { (items: [MediaResponse]) in
                XCTAssertEqual(items.count, 1)
                onSuccessCalled = true
            },
            onFailure: { error in
                onFailureCalled = true
                onFailureError = error
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callRequestCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: [MediaResponse(media: "test")]
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        XCTAssertFalse(onSuccessCalled)
        XCTAssertTrue(onFailureCalled)
        XCTAssertEqual(onFailureError as? ParleyRemoteError, .secretNotSet)
    }

    func testExecuteWithTypedResponseFailure() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

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
        try callRequestCompletion(parleyNetworkSessionSpy: parleyNetworkSessionSpy, response: ["test"])
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertFalse(onSuccessCalled)
        XCTAssertTrue(onFailureCalled)
    }

    func testExecuteWithNoTypedResponse() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

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
        try callRequestCompletion(parleyNetworkSessionSpy: parleyNetworkSessionSpy, response: ["test"])
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { parleyNetworkSessionSpy.requestDataMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
    }

    func testExecuteWithNoTypedResponseWhenSecretIsNotSet() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil },
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

        var onSuccessCalled = false
        var onFailureCalled = false
        var onFailureError: Error? = nil

        sut.execute(
            .post,
            path: "example/path",
            onSuccess: {
                onSuccessCalled = true
            },
            onFailure: { error in
                onFailureCalled = true
                onFailureError = error
            }
        )
        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callRequestCompletion(parleyNetworkSessionSpy: parleyNetworkSessionSpy, response: ["test"])
        mainQueueSpy.asyncExecuteReceivedWork?()

        XCTAssertFalse(onSuccessCalled)
        XCTAssertTrue(onFailureCalled)
        XCTAssertEqual(onFailureError as? ParleyRemoteError, .secretNotSet)
    }

    func testExecuteWithMultipartFormData() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

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
        try callUploadCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: ParleyResponse(data: [MediaResponse(media: "test")])
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
        XCTAssertTrue(multipartFormDataCalled)
    }

    func testExecuteWithMultipartFormDataWhenSecretIsNotSet() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil },
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

        var onSuccessCalled = false
        var onFailureCalled = false
        var onFailureError: Error? = nil
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
                onFailureError = error
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callUploadCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: ParleyResponse(data: [MediaResponse(media: "test")])
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        XCTAssertFalse(onSuccessCalled)
        XCTAssertTrue(onFailureCalled)
        XCTAssertEqual(onFailureError as? ParleyRemoteError, .secretNotSet)
        XCTAssertTrue(multipartFormDataCalled)
    }

    func testExecuteWithImageData() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

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
        try callUploadCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: ParleyResponse(data: [MediaResponse(media: "test")])
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        wait { parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(resultCalled)
    }

    func testExecuteWithImageDataWhenSecretIsNotSet() throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        let mainQueueSpy = QueueSpy()
        let backgroundQueueSpy = QueueSpy()

        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil },
            mainQueueSpy: mainQueueSpy,
            backgroundQueueSpy: backgroundQueueSpy
        )

        var resultCalled = false
        var resultError: Error? = nil

        sut.execute(
            path: "media",
            data: Data(),
            name: "image",
            fileName: "image.jpg",
            type: .imageJPeg,
            result: { (value: Result<[MediaResponse], Error>) in
                resultCalled = true
                switch value {
                case .failure(let error):
                    resultError = error
                case .success:
                    break
                }
            }
        )

        backgroundQueueSpy.asyncExecuteReceivedWork?()
        try callUploadCompletion(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            response: ParleyResponse(data: [MediaResponse(media: "test")])
        )
        mainQueueSpy.asyncExecuteReceivedWork?()

        XCTAssertTrue(resultCalled)
        XCTAssertEqual(resultError as? ParleyRemoteError, .secretNotSet)
    }

    // MARK: - MultipartFormData

    private func callRequestCompletion(parleyNetworkSessionSpy: ParleyNetworkSessionSpy, response: Encodable) throws {
        let arguments = parleyNetworkSessionSpy.requestDataMethodHeadersCompletionReceivedArguments
        try arguments?.completion(.success(createResponse(body: CodableHelper.shared.encode(response))))
    }

    private func callUploadCompletion(parleyNetworkSessionSpy: ParleyNetworkSessionSpy, response: Encodable) throws {
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

    private func makeSut(
        networkConfig: ParleyNetworkConfig = ParleyNetworkConfig(
            url: "https://api.parley.nu/",
            path: "/example",
            apiVersion: .v1_7
        ),
        parleyNetworkSessionSpy: ParleyNetworkSessionSpy = ParleyNetworkSessionSpy(),
        createSecretMock: @escaping (() -> String?) = { "secret" },
        createUniqueDeviceIdentifierMock: @escaping (() -> String?) = { "id" },
        createUserAuthorizationTokenMock: @escaping (() -> String?) = { "token" },
        mainQueueSpy: QueueSpy = QueueSpy(),
        backgroundQueueSpy: QueueSpy = QueueSpy()
    ) -> ParleyRemote {
        ParleyRemote(
            networkConfig: networkConfig,
            networkSession: parleyNetworkSessionSpy,
            createSecret: createSecretMock,
            createUniqueDeviceIdentifier: createUniqueDeviceIdentifierMock,
            createUserAuthorizationToken: createUserAuthorizationTokenMock,
            mainQueue: mainQueueSpy,
            backgroundQueue: backgroundQueueSpy
        )
    }
}
