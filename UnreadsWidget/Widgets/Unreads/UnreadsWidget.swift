//
//  UnreadsWidget.swift
//  UnreadsWidget
//
//  Created by Nikhil Nigade on 29/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import WidgetKit
import SwiftUI

import SDWebImage
import SDWebImageSwiftUI
import Models

struct PlaceholderView : View {
    
    var body: some View {
        
        ArticleView(entry: WidgetArticle())
        .redacted(reason: .placeholder)
        
    }
    
}

struct UnreadsWidget: Widget {
    
    private let kind: String = "UnreadsWidget"

    public var body: some WidgetConfiguration {
        
        IntentConfiguration(
            kind: kind,
            intent: UnreadsIntent.self,
            provider: UnreadsProvider()) { entries in
                UnreadsListView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .configurationDisplayName("Unread Articles")
        .description("Latest unread articles from your account.")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
    
}

/* Bundler */
@main
struct ElytraWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        UnreadsWidget()
        BloccsWidget()
        CountersWidget()
        FoldersWidget()
    }
}

//#if DEBUG
//
//struct UnreadsWidget_Previews: PreviewProvider {
//
//    static var previews: some View {
//
//        let entry1 = WidgetArticle(timestamp: Date(), title: "Apple releases second macOS Big Sur public beta", author: "Michael Potuck", blog: "9to5Mac", imageURL: "https://9to5mac.com/wp-content/uploads/sites/6/2020/07/macOS-Big-Sur-changes-and-features.jpg?quality=82&strip=all&w=1600", image: nil, identifier: 15930957, blogID: 19, favicon: "https://images.weserv.nl/?url=https://9to5mac.com/apple-touch-icon-180x180.png&w=128&dpr=3&output=&q=0.800000011920929@3x.&we")
//
//        let entry3 = WidgetArticle(timestamp: Date(), title: "How This iPhone Got FIXED!", author: "", blog: "Linus Tech Tips", imageURL: "https://images.weserv.nl/?url=https://i2.ytimg.com/vi/u1MNgP3LFM4/hqdefault.jpg&w=160&dpr=3&output=jpg&q=0.800000011920929&filename=hqdefault.@3x.jpg&we", image: nil, identifier: 15930980, blogID: 336, favicon: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo@3x.&we")
//
//        let entry2 = WidgetArticle(timestamp: Date(), title: "Apple hits $2 trillion – a record-breaking market cap milestone", author: "Tom Rolfe", blog: "TapSmart", imageURL: nil, image: nil, identifier: 15916691, blogID: 5959, favicon: "https://images.weserv.nl/?url=https://tapsmart-wpengine.netdna-ssl.com/wp-content/uploads/fbrfg/apple-touch-icon-180x180.png&w=128&dpr=3&output=&q=0.800000011920929@3x.&we")
//
//        let json = UnreadEntries(date: Date(), entries: [entry1, entry2, entry3])
//
//        UnreadsListView(entries: json)
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            .previewDisplayName("Unreads Large")
//
//        UnreadsListView(entries: json)
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDevice("Mac Catalyst")
//            .previewDisplayName("Unreads Medium")
//            .environment(\.colorScheme, .dark)
//
//        let emptyEntries = UnreadEntries(date: Date(), entries: [])
//
//        UnreadsListView(entries:emptyEntries)
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("Unreads Medium")
//            .environment(\.colorScheme, .dark)
//
//    }
//
//}
//
//#endif
