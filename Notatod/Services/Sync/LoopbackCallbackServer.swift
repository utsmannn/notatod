import Foundation
import Network

final class LoopbackCallbackServer {
    enum ServerError: Error, LocalizedError {
        case failedToStart
        case invalidRequest
        case cancelled

        var errorDescription: String? {
            switch self {
            case .failedToStart:
                return "Failed to start local OAuth callback server"
            case .invalidRequest:
                return "Invalid OAuth callback request"
            case .cancelled:
                return "OAuth callback server was cancelled"
            }
        }
    }

    private let queue = DispatchQueue(label: "com.notatod.sync.loopback-callback")
    private var listener: NWListener?
    private var callbackContinuation: CheckedContinuation<URL, Error>?
    private var startContinuation: CheckedContinuation<URL, Error>?
    private var hasResumedStartContinuation = false
    private var hasResumedCallbackContinuation = false

    func start() async throws -> URL {
        let listener = try NWListener(using: .tcp, on: 0)
        self.listener = listener
        startContinuation = nil
        hasResumedStartContinuation = false
        callbackContinuation = nil
        hasResumedCallbackContinuation = false

        return try await withCheckedThrowingContinuation { continuation in
            self.startContinuation = continuation

            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    guard let port = listener.port?.rawValue else {
                        self.resumeStartContinuation(with: .failure(ServerError.failedToStart))
                        self.stop()
                        return
                    }
                    listener.newConnectionHandler = { [weak self] connection in
                        self?.handle(connection: connection, port: port)
                    }
                    self.resumeStartContinuation(with: .success(URL(string: "http://127.0.0.1:\(port)/oauth2redirect")!))
                case .failed(let error):
                    self.resumeStartContinuation(with: .failure(error))
                    self.stop()
                case .cancelled:
                    self.resumeStartContinuation(with: .failure(ServerError.cancelled))
                default:
                    break
                }
            }

            listener.start(queue: queue)
        }
    }

    func waitForCallback() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.callbackContinuation = continuation
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func resumeStartContinuation(with result: Result<URL, Error>) {
        guard !hasResumedStartContinuation, let startContinuation else { return }
        hasResumedStartContinuation = true
        self.startContinuation = nil

        switch result {
        case .success(let url):
            startContinuation.resume(returning: url)
        case .failure(let error):
            startContinuation.resume(throwing: error)
        }
    }

    private func resumeCallbackContinuation(with result: Result<URL, Error>) {
        guard !hasResumedCallbackContinuation, let callbackContinuation else { return }
        hasResumedCallbackContinuation = true
        self.callbackContinuation = nil

        switch result {
        case .success(let url):
            callbackContinuation.resume(returning: url)
        case .failure(let error):
            callbackContinuation.resume(throwing: error)
        }
    }

    private func handle(connection: NWConnection, port: UInt16) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, error in
            guard let self else { return }

            defer {
                connection.cancel()
                self.stop()
            }

            if let error {
                self.resumeCallbackContinuation(with: .failure(error))
                return
            }

            guard let data,
                  let request = String(data: data, encoding: .utf8),
                  let requestLine = request.components(separatedBy: "\r\n").first,
                  requestLine.hasPrefix("GET ") else {
                self.resumeCallbackContinuation(with: .failure(ServerError.invalidRequest))
                return
            }

            let path = requestLine
                .replacingOccurrences(of: "GET ", with: "")
                .components(separatedBy: " HTTP/")
                .first ?? "/"

            guard let callbackURL = URL(string: "http://127.0.0.1:\(port)\(path)") else {
                self.resumeCallbackContinuation(with: .failure(ServerError.invalidRequest))
                return
            }

            let responseBody = "<html><body style=\"font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 24px;\"><h2>Notatod sync connected.</h2><p>You can close this window and return to the app.</p></body></html>"
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(responseBody.utf8.count)\r\nConnection: close\r\n\r\n\(responseBody)"
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })

            self.resumeCallbackContinuation(with: .success(callbackURL))
        }
    }
}
