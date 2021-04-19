//
//  FolderItemView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 19/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import Models
import WidgetKit
import SDWebImageSwiftUI

struct FolderItemView: View {
    
    var entry: WidgetArticle
    
    var body: some View {
        
        ZStack {
            
            WebImage(url: entry.coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .background(Color(.systemBackground))
                .alignmentGuide(VerticalAlignment.top) { _ in 0 }
            
        }
        
    }
}

struct FolderItemView_Previews: PreviewProvider {
    static var previews: some View {
        FolderItemView(entry: previewData.entries[0])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        FolderItemView(entry: previewData.entries[0])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
    }
}
