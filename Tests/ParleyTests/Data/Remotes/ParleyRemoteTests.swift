import Foundation
import Testing
@testable import Parley

@Suite
struct ParleyRemoteTests {
    
    private var sut: ParleyRemote!
    
    init() throws {
        self.sut = makeSut()
    }

    // MARK: - Execute request

    @Test
    mutating func testExecuteWithTypedResponseSuccess() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        sut = makeSut(parleyNetworkSessionSpy: parleyNetworkSessionSpy)
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.requestDataMethodHeadersResult = .success(try createResponse(response: response))
        let result: [MediaResponse] = try await sut.execute(.get, path: "path", keyPath: .none)
        #expect(result.count == 1)
    }

    @Test
    mutating func testExecuteWithTypedResponseFailureWhenSecretIsNotSet() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil }
        )
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.requestDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(performing: {
            let _: [MediaResponse] = try await sut.execute(.get, path: "path", keyPath: .none)
        }, throws: { error in
            return (error as? ParleyRemoteError) == .secretNotSet
        })
    }

    @Test
    mutating func testExecuteWithTypedResponseFailure() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy
        )
        
        let response = ["test"]
        parleyNetworkSessionSpy.requestDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(throws: Error.self, performing: {
            let _: [MediaResponse] = try await sut.execute(.get, path: "path", keyPath: .none)
        })
    }
    
    @Test
    mutating func testExecuteWithNoTypedResponse() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(parleyNetworkSessionSpy: parleyNetworkSessionSpy)
        
        let response = ["test"]
        parleyNetworkSessionSpy.requestDataMethodHeadersResult = .success(try createResponse(response: response))
        
        try await sut.execute(.post, path: "example/path")
    }
    
    @Test
    mutating func testExecuteWithNoTypedResponseWhenSecretIsNotSet() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil }
        )
        
        let response = ["test"]
        parleyNetworkSessionSpy.requestDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(performing: {
            try await sut.execute(.post, path: "example/path")
        }, throws: { error in
            return (error as? ParleyRemoteError) == .secretNotSet
        })
    }
    
    @Test
    mutating func testExecuteWithMultipartFormData() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(parleyNetworkSessionSpy: parleyNetworkSessionSpy)
        var multipartFormDataCalled = false
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.uploadDataMethodHeadersResult = .success(try createResponse(response: response))
        let _: [MediaResponse] = try await sut.execute(.post, path: "", multipartFormData: { _ in
            multipartFormDataCalled = true
        }, keyPath: .none)
        
        #expect(multipartFormDataCalled)
    }
    
    @Test
    mutating func testExecuteWithMultipartFormDataWhenSecretIsNotSet() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil }
        )
        
        var multipartFormDataCalled = false
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.uploadDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(performing: {
            let _: [MediaResponse] = try await sut.execute(
                .post,
                path: "example/path",
                multipartFormData: { _ in
                    multipartFormDataCalled = true
                })
        }, throws: { error in
            return (error as? ParleyRemoteError) == .secretNotSet
        })
        #expect(multipartFormDataCalled)
    }
    
    @Test
    mutating func testExecuteWithImageData() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(parleyNetworkSessionSpy: parleyNetworkSessionSpy)
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.uploadDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(throws: Error.self, performing: {
            let _: [MediaResponse] = try await sut.execute(
                path: "media",
                data: Data(),
                name: "image",
                fileName: "image.jpg",
                type: .imageJPeg
            )
        })
    }
    
    @Test
    mutating func testExecuteWithImageDataWhenSecretIsNotSet() async throws {
        let parleyNetworkSessionSpy = ParleyNetworkSessionSpy()
        
        sut = makeSut(
            parleyNetworkSessionSpy: parleyNetworkSessionSpy,
            createSecretMock: { nil }
        )
        
        let response = [MediaResponse(media: "test")]
        parleyNetworkSessionSpy.uploadDataMethodHeadersResult = .success(try createResponse(response: response))
        
        await #expect(performing: {
            let _: [MediaResponse] = try await sut.execute(
                path: "media",
                data: Data(),
                name: "image",
                fileName: "image.jpg",
                type: .imageJPeg
            )
        }, throws: { error in
            return (error as? ParleyRemoteError) == .secretNotSet
        })
    }
}

// MARK: - Privates
extension ParleyRemoteTests {
    
    func createResponse(response: Encodable) throws -> ParleyHTTPDataResponse {
        let encodedResponse = try CodableHelper.shared.encode(response)
        return createResponse(body: encodedResponse)
    }

    func createResponse(
        body: Data = Data(),
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) -> ParleyHTTPDataResponse {
        ParleyHTTPDataResponse(body: body, statusCode: statusCode, headers: headers)
    }

    func makeSut(
        networkConfig: ParleyNetworkConfig = ParleyNetworkConfig(
            url: "https://api.parley.nu/",
            path: "/example",
            apiVersion: .v1_7
        ),
        parleyNetworkSessionSpy: ParleyNetworkSessionSpy = ParleyNetworkSessionSpy(),
        createSecretMock: @escaping (() -> String?) = { "secret" },
        createUniqueDeviceIdentifierMock: @escaping (() -> String?) = { "id" },
        createUserAuthorizationTokenMock: @escaping (() -> String?) = { "token" }
    ) -> ParleyRemote {
        ParleyRemote(
            networkConfig: networkConfig,
            networkSession: parleyNetworkSessionSpy,
            createSecret: createSecretMock,
            createUniqueDeviceIdentifier: createUniqueDeviceIdentifierMock,
            createUserAuthorizationToken: createUserAuthorizationTokenMock
        )
    }
}
