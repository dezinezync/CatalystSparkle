//
//  BloccView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit
import SDWebImageSwiftUI
import Models

struct BloccView: View {
    
    var entry: WidgetArticle
    
    var body: some View {
        
        Link(destination:URL(string: "elytra://feed/\(entry.feedID)/article/\(entry.identifier!)")!) {
            
            GeometryReader { geometry in
                
                ZStack(alignment: .topLeading) {
                                
                    WebImage(url: entry.coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(Color(.systemBackground))
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: geometry.size.width,
                               maxHeight: geometry.size.height)
                        .clipped()
                
                    LinearGradient(gradient: Gradient(colors: [.black.opacity(0.5), .black.opacity(0.2)]), startPoint: .bottom, endPoint: .top)
                
                    Text(entry.title!)
                        .platformBoldTitleFont()
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 0, leading: 12, bottom: 8, trailing: 12))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        .alignmentGuide(.top, computeValue: { dimension in
                            return  -geometry.size.height + dimension.height + 5
                        })
                    
                    if entry.favicon != nil {
                        
                        WebImage(url: entry.favicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color(.clear))
                            .frame(width: 24, height: 24)
                            .clipped()
                            .cornerRadius(3.0)
                            .alignmentGuide(.top, computeValue: { dimension in
                                return -12
                            })
                            .alignmentGuide(.leading, computeValue: { dimension in
                                return -12
                            })
                            
                    }
                
                }
            
            }
            
        }
        
    }
    
}

#if DEBUG
struct BloccView_Previews: PreviewProvider {
    static var previews: some View {
        BloccView(entry: previewData.entries[0])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
