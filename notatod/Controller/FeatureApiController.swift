//
// Created by utsman on 06/03/21.
//

import Foundation

class FeatureApiController {

    private let pathVersion = "/version"
    private let pathFeature = "/feature"

    private var networkTask: Network.NetworkTask? {
        NetworkBuilder(session: URLSession.shared)
                .baseUrl(url: "https://notatod-updater.herokuapp.com")
                .buildTask(enableDebugPrint: true)
    }

    func checkUpdateAvailable(onResult: @escaping (VersionResponse.MacOs) -> ()) {
        networkTask?.request(path: pathVersion, method: .get)
                .start()
                .onSuccess { data in
                    do {
                        let macOsVersion: VersionResponse = try data.decodeData()
                        onResult(macOsVersion.macOS)
                    } catch {
                        log(error)
                        return
                    }
                }.onFailure { error in
                    log(error)
                }
    }
    
    func isGoogleAuthEnable(onResult: @escaping (Bool) -> ()) {
        networkTask?.request(path: pathFeature, method: .get)
                .start()
                .onSuccess { data in
                    do {
                        let feature: FeatureResponse = try data.decodeData()
                        let isGoogleAuthEnable = feature.googleAuth
                        onResult(isGoogleAuthEnable)
                    } catch {
                        return
                    }
                }.onFailure { error in
                }
    }
}
