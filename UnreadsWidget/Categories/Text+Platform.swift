//
//  Text+Platform.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import SwiftUI

extension Text {
    
    func platformTitleFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 14)).fontWeight(.semibold)
        #elseif canImport(UIKit)
        return self.font(.system(size: 15)).fontWeight(.medium)
        #else
        return self;
        #endif
        
    }
    
    func platformBodyFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 14)).fontWeight(.regular)
        #elseif canImport(UIKit)
        return self.font(.system(size: 15)).fontWeight(.regular)
        #else
        return self;
        #endif
        
    }
    
    func platformCaptionFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 13)).fontWeight(.bold)
        #elseif canImport(UIKit)
        return self.font(.system(size: 13)).fontWeight(.semibold)
        #else
        return self;
        #endif
        
    }
    
}
