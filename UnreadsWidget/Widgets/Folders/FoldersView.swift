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
    
    var collection: FoldersCollection
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                BloccView(entry: collection.mainItem)
                
                if collection.otherItems.count > 0 {
                    
                    ZStack {
                        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [], content: {
                            
                            ForEach(collection.otherItems[0..<min(3, collection.otherItems.count)], id: \.self) { item in
                                ArticleView(entry: item)
                            }
                            
                        })
                        .alignmentGuide(.top) { _ in 0 }
                    }
                    .padding()
                    
                }
                else {
                    
                    EmptyView(title: "No unreads in this folder")
                    
                }
                
            }
        }
        .background(Color(.systemBackground))
        
    }
}

#if DEBUG
import Models

struct FoldersView_Previews: PreviewProvider {
    
    static let collection: FoldersCollection = {
       
        let mainItem: WidgetArticle = previewData.entries.first(where: { $0.coverImage != nil })!
        let otherItems: [WidgetArticle] = previewData.entries.filter { $0.identifier != mainItem.identifier }
        
        let collection = FoldersCollection(mainItem: mainItem, otherItems: otherItems)
        
        return collection
        
    }()
    
    static var previews: some View {
        FoldersView(collection: FoldersView_Previews.collection)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        
        FoldersView(collection: FoldersView_Previews.collection)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.colorScheme, .dark)
    }
}
#endif
