import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.notatod.sync.network-monitor", qos: .utility)

    var onStatusChange: ((Bool) -> Void)?
    private(set) var isOnline = true

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            self?.isOnline = online
            self?.onStatusChange?(online)
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
