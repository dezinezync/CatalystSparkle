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
    static let article = Self("article")
    static let misc = Self("misc")
}

@objc final class PreferencesController : NSViewController {
    
    lazy var preferences: [PreferencePane] = [
        GeneralPreferenceViewController(),
        ImagesPreferenceViewController(),
        ArticlePreferenceViewController(),
        MiscPreferenceViewController()
    ]

    @objc lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: preferences,
        style: .toolbarItems,
        animated: true,
        hidesToolbarForSingleItem: true
    )

    @objc public func show() {
        preferencesWindowController.show()
    }

}
