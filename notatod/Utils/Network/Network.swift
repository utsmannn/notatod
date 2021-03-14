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
        private var valuesAdditional: [[String: String]] = [[String: String]]()
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
                bodyString.append("&\(key)=\(value)")
            }

            return self
        }

        func addRawBody(body: String) -> Request {
            bodyString = body
            return self
        }

        func addValueHeader(key: String, value: String) -> Request {
            let param = [key: value]
            valuesAdditional.append(param)
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
            if authorizationKey != "" {
                request.addValue(authorizationKey, forHTTPHeaderField: "Authorization")
            }

            log("additional values -----> \(valuesAdditional)")
            valuesAdditional.forEach { dictionary in
                dictionary.forEach { key, value in
                    request.addValue(key, forHTTPHeaderField: value)
                }
            }
            request.httpBody = bodyData

            DispatchQueue.global(qos: .background).async {
                let task = self.session.dataTask(with: request) { data, response, error in
                    guard let data = data else {
                        network.error = Error.invalid_response
                        network.semaphore.signal()
                        log("\(request.httpMethod!) | \(request.url!) | RESPONSE ERROR -> \(error!) \n --- END --- \n\n")
                        return
                    }

                    network.data = data
                    log("\(request.httpMethod!) | \(request.url!) | RESPONSE SUCCESS -> \(String(data: data, encoding: .utf8)!) \n --- END -- \n\n")
                    network.semaphore.signal()
                }

                task.resume()
            }
            network.semaphore.wait()
            return network
        }

        func start(completion: @escaping (Result<Data, Error>) -> ()) {
            var request = URLRequest(url: URL(string: "\(baseUrl)\(path)")!, timeoutInterval: Double.infinity)
            let bodyData = bodyString.data(using: .utf8, allowLossyConversion: false)

            request.httpMethod = methodString
            request.addValue(contentTypeValue, forHTTPHeaderField: "Content-Type")
            if authorizationKey != "" {
                request.addValue(authorizationKey, forHTTPHeaderField: "Authorization")
            }

            log("additional values -----> \(valuesAdditional)")
            valuesAdditional.forEach { dictionary in
                dictionary.forEach { key, value in
                    request.addValue(value, forHTTPHeaderField: key)
                }
            }

            request.httpBody = bodyData

            DispatchQueue.global(qos: .background).async {
                let task = self.session.dataTask(with: request) { data, response, error in
                    guard let data = data else {
                        log("\(request.httpMethod!) | \(request.url!) | RESPONSE ERROR -> \(error!) \n --- END --- \n\n")
                        completion(.failure(.invalid_response))
                        return
                    }

                    log("\(request.httpMethod!) | \(request.url!) | RESPONSE SUCCESS -> \(String(data: data, encoding: .utf8)!) \n --- END -- \n\n")
                    completion(.success(data))
                }

                task.resume()
            }
        }
    }

    func onSuccess(success: @escaping (Data) -> ()) -> Network {
        DispatchQueue.global(qos: .utility).async {
            success(data)
        }
        return self
    }

    func onFailure(failure: @escaping (Error) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            guard let error = error else {
                return
            }
            failure(error)
        }
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