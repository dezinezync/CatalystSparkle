//
//  PreferencesController.swift
//  elytramac
//
//  Created by Nikhil Nigade on 26/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Cocoa

extension Preferences.PaneIdentifier {
    static let general = Self("general")
    static let images = Self("images")
    static let advanced = Self("advanced")
}

@objc final class PreferencesController : NSViewController {
    
    var preferencesStyle: Preferences.Style {
        return .toolbarItems
    }

    lazy var preferences: [PreferencePane] = [
        GeneralPreferenceViewController(),
        ImagesPreferenceViewController()
//        AdvancedPreferenceViewController()
    ]

    @objc lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: preferences,
        style: preferencesStyle,
        animated: true,
        hidesToolbarForSingleItem: true
    )

    @objc public func preferencesMenuItemActionHandler(_ sender: NSMenuItem) {
        preferencesWindowController.show()
    }

}
