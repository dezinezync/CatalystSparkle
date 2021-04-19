//
//  FoldersWidget.swift
//  Elytra
//
//  Created by Nikhil Nigade on 18/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit
import Models

struct FoldersWidget: Widget {

    private let kind: String = "Folders Widget"
    
    public var body: some WidgetConfiguration {
        
        IntentConfiguration(
            kind: kind,
            intent: FoldersIntent.self,
            provider: FoldersProvider()) { entries in
            
            FoldersView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
        }
        .configurationDisplayName("Folders - Unreads")
        .description("Latest unread articles from a folder")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
    
}
