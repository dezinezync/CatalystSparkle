//
//  UnreadsWidget.swift
//  UnreadsWidget
//
//  Created by Nikhil Nigade on 29/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    
    public func snapshot(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (SimpleEntries) -> ()) {
        
        let entries =  SimpleEntries(date: Date(), entries: [
            SimpleEntry(date: Date(), title: "iOS 14 Review with a long title to check", author: "Federico Viticci", blog: "MacStories", image: nil, imageURL: nil, configuration: configuration),
            SimpleEntry(date: Date(), title: "iOS 15 Review", author: "John Gruber", blog: "Daring Fireball", image: nil, imageURL: nil, configuration: configuration)
        ])

        completion(entries)
        
    }

    public func timeline(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (Timeline<SimpleEntries>) -> ()) {
        
        var entries: [SimpleEntries] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        
        let entryCol = SimpleEntries(date: currentDate, entries: [
            SimpleEntry(date: Date(), title: "iOS 14 Review with a long title to check", author: "Federico Viticci", blog: "MacStories", image: nil, imageURL: nil, configuration: configuration),
            SimpleEntry(date: Date(), title: "iOS 15 Review", author: "John Gruber", blog: "Daring Fireball", image: nil, imageURL: nil, configuration: configuration)
        ])
        
        entries.append(entryCol)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
   
    }
    
}

struct SimpleEntry: TimelineEntry, Hashable, Identifiable {
    public let date: Date
    public let title: String
    public let author: String
    public let blog: String
    public let image: Image?
    public let imageURL: URL?
    public let configuration: ConfigurationIntent?
    
    var hashValue : Int {
        return title.hashValue
    }
    
    var id : Int {
        return hashValue
    }
    
}

struct SimpleEntries: TimelineEntry {
    public let date: Date
    public let entries: [SimpleEntry]
}

struct PlaceholderView : View {
    
    var body: some View {
        
        ArticleView(entry: SimpleEntry(date: Date(), title: "Placeholder title", author: "Author", blog: "Blog", image: nil, imageURL: nil, configuration: nil))
        .redacted(reason: .placeholder)
        
    }
    
}

struct ArticleView : View {
    
    var entry: SimpleEntry
    
    var body: some View {
        
        ZStack {
        
            HStack(alignment: .center, spacing: 12) {
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(entry.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                        .lineLimit(1)
                    
                    Text("\(entry.author) - \(entry.blog)")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }

                }
                
                Spacer()
                
                Image(systemName: "square.dashed")
                    .frame(width: 40, height: 40, alignment: .trailing)
                    .foregroundColor(.secondary)
                    .alignmentGuide(HorizontalAlignment.trailing) { _ in
                        0
                    }
                
            }
            
        }
        
    }
        
}

struct UnreadsWidgetEntryView : View {
    
    var entries: SimpleEntries

    var body: some View {
        
        VStack (alignment: .leading, spacing: 4) {
            
            Text("Recent Unreads")
                .font(.headline)
                .foregroundColor(.purple)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            GeometryReader { geometryProxy in
                
                LazyVStack(alignment: .leading, spacing: 4, pinnedViews: [], content: {
                    ForEach(0..<entries.entries.count, id: \.self) { count in
                        ArticleView(entry: entries.entries[count])
                    }
                })
//                .frame(width: geometryProxy.size.width, height: geometryProxy.size.height, alignment: .topLeading)
                
            }
            
        }
        .padding()
        
    }
}

@main
struct UnreadsWidget: Widget {
    
    private let kind: String = "UnreadsWidget"

    public var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entries in
            UnreadsWidgetEntryView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .configurationDisplayName("Unread Articles")
        .description("Latest unread articles from your account.")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
    
}

//#if DEBUG
//
//struct UnreadsWidget_Previews: PreviewProvider {
//
//    static var previews: some View {
//
//        UnreadsWidgetEntryView(entries: [SimpleEntry(date: Date(), title: "Article Title", author: "Author", blog: "Blog", image: nil, imageURL: nil, configuration: ConfigurationIntent())])
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//
//    }
//
//}
//
//#endif
