//
//  FoldersView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 19/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit

struct FoldersView: View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entries: UnreadEntries
    
    var usedCover: Bool {
        
        if let _ = entries.entries.first(where: { i in
            return i.coverImage != nil
        }) {
            return true
        }
        
        return false
        
    }
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                if let entry = entries.entries.first(where: { i in
                    return i.coverImage != nil
                }) {
                    BloccView(entry: entry)
                }
                
                ZStack {
                    LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [], content: {
                        ForEach((usedCover ? 1 : 0)...[entries.entries.count - (usedCover ? 1 : 0), 3].min()!, id: \.self) { count in
                            ArticleView(entry: entries.entries[count])
                        }
                    })
                    .alignmentGuide(.top) { _ in 0 }
                }
                .padding()
                
            }
        }
        .background(Color(.systemBackground))
        
    }
}

struct FoldersView_Previews: PreviewProvider {
    static var previews: some View {
        FoldersView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        
        FoldersView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.colorScheme, .dark)
    }
}
