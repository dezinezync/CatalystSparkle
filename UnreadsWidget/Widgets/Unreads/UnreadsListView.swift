//
//  UnreadsListView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import SwiftUI

struct UnreadsListView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entries: UnreadEntries

    var body: some View {
        
        ZStack {
            
            VStack (alignment: .leading, spacing: (widgetFamily == .systemMedium ? 4 : 8)) {
                
                Text("Recent Unreads")
                    .font(.system(size: 17)).fontWeight(.bold)
                    .foregroundColor(Color(UIColor.systemIndigo))
                    .multilineTextAlignment(.leading)
                
                if (entries.entries.count == 0) {
                    
                    VStack(alignment: .leading, spacing: nil, content: {
                        
                        Text("No new unread articles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        
                    })
                    
                }
                else {
                    
                    if (widgetFamily == .systemMedium) {
                        
                        LazyVStack(alignment: .leading, spacing: 4, pinnedViews: [], content: {
                            ForEach(0..<[entries.entries.count, 2].min()!, id: \.self) { count in
                                ArticleView(entry: entries.entries[count])
                            }
                        })
                        
                    }
                    else {
                        
                        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [], content: {
                            ForEach(0..<[entries.entries.count, 4].min()!, id: \.self) { count in
                                ArticleView(entry: entries.entries[count])
                            }
                        })
                        .alignmentGuide(.top) { _ in 0 }
                        
                    }
                    
                }
                
                Spacer(minLength: 0)
                
            }
            
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}
