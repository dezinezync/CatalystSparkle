//
//  Environment.swift
//  Elytra
//
//  Created by Nikhil Nigade on 16/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation

public enum Environment {
    
    // MARK: - Keys
    enum Keys {
        enum Plist {
            static let isMacNotarized = "Notarized"
            static let fullVersion = "CFBundleShortVersionString"
        }
    }
    
    // MARK: - Plist
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

    // MARK: - Plist Values
    static let isMacNotarized: Bool = {
        guard let notarized = Environment.infoDictionary[Keys.Plist.isMacNotarized] as? String else {
            fatalError("Notarized not set in plist for this environment")
        }
        return notarized == "YES"
    }()
    
    static let fullVersion: String = {
        guard let fullVersion = Environment.infoDictionary[Keys.Plist.fullVersion] as? String else {
            fatalError("Notarized not set in plist for this environment")
        }
        return fullVersion
    }()
    
}
