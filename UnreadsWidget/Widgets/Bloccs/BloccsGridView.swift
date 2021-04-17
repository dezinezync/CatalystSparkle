//
//  BloccsGridView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit

struct BloccsGridView: View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var gridColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var entries: UnreadEntries
    
    var body: some View {
        
        if (entries.entries.count == 0) {
            
            EmptyView(title: "No new unread articles")
                .padding()
            
        }
        else {
        
            let limit: Int = widgetFamily == .systemMedium ? 2 : min(6, entries.entries.count)
                   
            ZStack(alignment: .leading) {
                
                LazyVGrid(columns: gridColumns, content: {
                    
                    ForEach(entries.entries[0..<limit], id: \.self) { entry in
                        BloccView(entry: entry)
                            .cornerRadius(10, antialiased: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                            .frame(height: widgetFamily == .systemMedium ? 131 : 101)
                    }
                    
                })

            }
            .frame(maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
            )
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .background(Color(.systemBackground))
            
        }
        
    }
}

struct BloccsGridView_Previews: PreviewProvider {
    static var previews: some View {
        
        BloccsGridView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        
        BloccsGridView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.colorScheme, .dark)
    }
}
