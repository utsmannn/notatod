//
// Created by utsman on 06/03/21.
//

import Foundation

class FeatureApiController {

    private let pathVersion = "/version"
    private let pathFeature = "/v1/feature"

    private var networkTask: Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: "https://notatod-updater.herokuapp.com")
                .buildTask(enableDebugPrint: true)
    }

    func checkUpdateAvailable(onResult: @escaping (VersionResponse.MacOs) -> ()) {
        networkTask?.request(path: pathVersion, method: .get)
                .start { result in
                    result.doOnSuccess { data in
                        do {
                            let macOsVersion: VersionResponse = try data.decodeData()
                            onResult(macOsVersion.macOS)
                        } catch {
                            log(error)
                            return
                        }
                    }
                    result.doOnFailure { error in
                        log(error)
                    }
                }
    }

    func authServiceEnable(onResult: @escaping (AuthType) -> ()) {
        networkTask?.request(path: pathFeature, method: .get)
                .start { result in
                    switch result {
                    case .success(let data):
                        do {
                            let response: FeatureResponse = try data.decodeData()
                            let authService = response.asAuthEnable()
                            onResult(authService)
                        } catch {
                            return
                        }
                    case .failure(let error):
                        log(error)
                        onResult(.disable)
                    }
                }
    }
}
