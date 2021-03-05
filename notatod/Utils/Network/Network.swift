//
// Created by utsman on 03/03/21.
//

import Foundation

struct Network {

    private var data = Data()
    private var error: Error?
    private var enableDebugPrint: Bool = false

    private var semaphore = DispatchSemaphore(value: 0)

    class NetworkTask {
        private var session: URLSessionProtocol
        private var baseUrl: String
        private var contentTypeValue: String
        private var enableDebugPrint: Bool
        private var authorizationKey: String

        private var bodyString = ""
        private var methodString = ""

        init(session: URLSessionProtocol, baseUrl: String, contentTypeValue: String, enableDebugPrint: Bool, authorizationKey: String) {
            self.session = session
            self.baseUrl = baseUrl
            self.contentTypeValue = contentTypeValue
            self.enableDebugPrint = enableDebugPrint
            self.authorizationKey = authorizationKey
        }

        func request(path: String, method: Method) -> Network.Request {
            let methodString = method.rawValue
            return Request(
                    session: session,
                    baseUrl: baseUrl,
                    contentTypeValue: contentTypeValue,
                    methodString: methodString,
                    path: path,
                    authorizationKey: authorizationKey
            )
        }
    }

    class Request {
        private var session: URLSessionProtocol
        private var baseUrl: String
        private var contentTypeValue: String
        private var methodString: String
        private var path: String
        private var authorizationKey: String
        private var bodyString = ""

        init(session: URLSessionProtocol, baseUrl: String, contentTypeValue: String, methodString: String, path: String, authorizationKey: String) {
            self.session = session
            self.baseUrl = baseUrl
            self.contentTypeValue = contentTypeValue
            self.methodString = methodString
            self.path = path
            self.authorizationKey = authorizationKey
        }

        func addParams(params: [String: String]) -> Request {
            let string = params.map { key, value -> String in
                "\(key)=\(value)"
            }.joined(separator: "&")

            if methodString == Method.get.rawValue {
                path.append("?\(string)")
            } else {
                bodyString.append(string)
            }
            return self
        }

        func addParam(key: String, value: String) -> Request {
            if methodString == Method.get.rawValue {
                path.append("?\(key)=\(value)")
            } else {
                bodyString.append("\(key)=\(value)")
            }

            return self
        }

        func addRawBody(body: String) -> Request {
            bodyString = body
            return self
        }

        func addContentType(contentType: ContentType) -> Request {
            contentTypeValue = contentType.rawValue
            return self
        }

        func start() -> Network {
            var network = Network()
            var request = URLRequest(url: URL(string: "\(baseUrl)\(path)")!, timeoutInterval: Double.infinity)
            let bodyData = bodyString.data(using: .utf8, allowLossyConversion: false)

            request.httpMethod = methodString
            request.addValue(contentTypeValue, forHTTPHeaderField: "Content-Type")
            log("type value --> \(contentTypeValue)")
            if authorizationKey != "" {
                request.addValue(authorizationKey, forHTTPHeaderField: "Authorization")
            }
            request.httpBody = bodyData


            let task = session.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    network.error = Error.invalidResponse
                    network.semaphore.signal()
                    if network.enableDebugPrint {
                        log(error!)
                    }
                    return
                }

                network.data = data
                if network.enableDebugPrint {
                    log("NETWORK - DATA RESPONSE: \(String(data: data, encoding: .utf8)!)")
                }
                network.semaphore.signal()
            }

            task.resume()
            network.semaphore.wait()
            return network
        }
    }

    func onSuccess(success: @escaping (Data) -> ()) -> Network {
        success(data)
        return self
    }

    func onFailure(failure: @escaping (Error) -> ()) {
        guard let error = error else {
            return
        }
        failure(error)
    }
}

class NetworkBuilder {
    private var session: URLSessionProtocol
    private var url: String = ""
    internal var contentTypeValue = ContentType.application_json.rawValue
    private var authorizationKey = ""

    init(session: URLSessionProtocol) {
        self.session = session
    }

    func baseUrl(url: String) -> NetworkBuilder {
        self.url = url
        return self
    }

    func withAuthorization(authorization: String) -> NetworkBuilder {
        authorizationKey = authorization
        return self
    }

    func withContentType(contentType: ContentType) -> NetworkBuilder {
        contentTypeValue = contentType.rawValue
        return self
    }

    func buildTask(enableDebugPrint: Bool = false) -> Network.NetworkTask? {
        Network.NetworkTask(
                session: session,
                baseUrl: url,
                contentTypeValue: contentTypeValue,
                enableDebugPrint: enableDebugPrint,
                authorizationKey: authorizationKey
        )
    }
}