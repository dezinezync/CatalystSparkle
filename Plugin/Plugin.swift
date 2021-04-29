// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import AppKit
import Sparkle

@objc class Plugin: NSResponder, SparkleBridgePlugin, SPUStandardUserDriverDelegate, SPUUpdaterDelegate {
    var driver: SPUStandardUserDriver!
    var updater: SPUUpdater!
    
    func setup(_ bridge: SparkleBridge?) throws {
        let hostBundle = Bundle.main
        driver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: self)
        updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: hostBundle, userDriver: driver, delegate: self)
        try updater.start()
    }
    
    func checkForUpdates() {
        updater.checkForUpdates()
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("aborted \(error)")
    }
    
    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        print("failed to download update")
    }
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("Will install update")
    }
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        print("Did find valid update")
    }
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("Did not find valid update")
    }
}
