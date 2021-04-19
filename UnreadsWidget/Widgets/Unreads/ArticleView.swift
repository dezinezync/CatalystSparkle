//
//  ArticleView.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import Models

struct ArticleView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: WidgetArticle
    
    var body: some View {
        
        Link(destination:URL(string: "elytra://feed/\(entry.feedID)/article/\(entry.identifier!)")!) {
            
            let maxDim : CGFloat = widgetFamily == .systemLarge ? 64 : 46;
            
            ZStack {
            
                HStack(alignment: .top, spacing: 12) {
                    
                    if entry.showFavicon == true {
                        
                        if entry.favicon != nil {
                            WebImage(url: entry.favicon!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 24, maxHeight: 24, alignment: .center)
                                .clipped()
                                .cornerRadius(3.0)
                                .background(Color(.systemBackground))
                                .alignmentGuide(VerticalAlignment.top) { _ in -4 }
                            
                        }
                        else {
                            
                            Image(systemName: "square.dashed")
                                .frame(maxWidth: 24, maxHeight: 24, alignment: .center)
                                .background(Color(.systemBackground))
                                .alignmentGuide(VerticalAlignment.top) { _ in -4 }
                            
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        
                        if let title = entry.title, title.isEmpty == false {
                            
                            Text(title)
                                .platformTitleFont()
                                .foregroundColor(.primary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                                .lineLimit(2)
                            
                        }
                        else if let content = entry.summary, content.isEmpty == false {
                            
                            Text(content)
                                .platformBodyFont()
                                .foregroundColor(.primary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                                .lineLimit(2)
                            
                        }
                        
                        if (entry.author == entry.blog) {
                            
                            Text(entry.blog ?? "No Blog")
                                .platformCaptionFont()
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            
                        }
                        else {
                            
                            Text("\(entry.author ?? "") - \(entry.blog ?? "")")
                                .platformCaptionFont()
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            
                        }
                        
                    }
                    
                    Spacer(minLength: 4)
                    
                    if entry.showCover == true && entry.coverImage != nil {
                        
                        WebImage(url: entry.coverImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: maxDim, maxWidth: maxDim, minHeight: maxDim, maxHeight: maxDim, alignment: .center)
                            .clipped()
                            .cornerRadius(8.0)
                            .background(Color(.systemBackground))
                            .alignmentGuide(VerticalAlignment.top) { _ in 0 }
                        
                    }
                    
                }
                
            }
            .frame(minHeight: maxDim, maxHeight: maxDim)
        }
        
    }
        
}
