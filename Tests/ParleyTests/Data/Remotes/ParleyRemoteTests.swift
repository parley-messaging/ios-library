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

    override func setUpWithError() throws {
        parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        parleyNetworkSessionSpy.requestMethodParametersHeadersCompletionReturnValue = RequestCancelableStub()
        parleyNetworkSessionSpy.uploadDataToMethodHeadersReturnValue = RequestCancelableStub()
        parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionReturnValue = RequestCancelableStub()

        networkConfig = ParleyNetworkConfig(
            url: "https://api.parley.nu/",
            path: "/example",
            apiVersion: .v1_6
        )
        createSecretMock = { "secret" }
        createUniqueDeviceIdentifierMock = { "id" }
        createUserAuthorizationTokenMock = { "token" }
        sut = ParleyRemote(
            networkConfig: networkConfig,
            networkSession: parleyNetworkSessionSpy,
            createSecret: createSecretMock,
            createUniqueDeviceIdentifier: createUniqueDeviceIdentifierMock,
            createUserAuthorizationToken: createUserAuthorizationTokenMock
        )
    }

    override func tearDownWithError() throws {
        parleyNetworkSessionSpy = nil
        createSecretMock = nil
        networkConfig = nil
        createSecretMock = nil
        createUniqueDeviceIdentifierMock = nil
    }

    // MARK: - Execute request

    func testExecuteWithTypedResponseSuccess() throws {
        var onSuccessCalled = false
        var onFailureCalled = false

        sut.execute(
            .get,
            path: "path",
            parameters: [:],
            keyPath: .none,
            onSuccess: { (items: [MediaResponse]) in
                XCTAssertEqual(items.count, 1)
                onSuccessCalled = true
            },
            onFailure: { _ in
                onFailureCalled = true
            }
        )

        try callRequestCompletion(response: [MediaResponse(media: "test")])

        wait { self.parleyNetworkSessionSpy.requestMethodParametersHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
    }

    func testExecuteWithTypedResponseFailure() throws {
        var onSuccessCalled = false
        var onFailureCalled = false

        sut.execute(
            .get,
            path: "path",
            parameters: [:],
            keyPath: .none,
            onSuccess: { (_: [MediaResponse]) in
                onSuccessCalled = true
            },
            onFailure: { _ in
                onFailureCalled = true
            }
        )

        try callRequestCompletion(response: ["test"])

        wait { self.parleyNetworkSessionSpy.requestMethodParametersHeadersCompletionCalled }
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

        try callRequestCompletion(response: ["test"])

        wait { self.parleyNetworkSessionSpy.requestMethodParametersHeadersCompletionCalled }
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

        try callUploadCompletion(response: ParleyResponse(data: [MediaResponse(media: "test")]))

        wait { self.parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(onSuccessCalled)
        XCTAssertFalse(onFailureCalled)
        XCTAssertTrue(multipartFormDataCalled)
    }

    func testExecuteWithImageData() throws {
        var resultCalled = false

        sut.execute(
            path: "media",
            imageData: Data(),
            name: "image",
            fileName: "image.jpg",
            imageType: .jpg,
            result: { (_: Result<[MediaResponse], Error>) in
                resultCalled = true
            }
        )

        try callUploadCompletion(response: ParleyResponse(data: [MediaResponse(media: "test")]))

        wait { self.parleyNetworkSessionSpy.uploadDataToMethodHeadersCompletionCalled }
        XCTAssertTrue(resultCalled)
    }
    
    // MARK: - MultipartFormData

    private func callRequestCompletion(response: Encodable) throws {
        let arguments = parleyNetworkSessionSpy.requestMethodParametersHeadersCompletionReceivedArguments
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
