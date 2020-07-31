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
    
    public func snapshot(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), title: "iOS 14 Review", author: "Federico Viticci", blog: "MacStories", image: nil, imageURL: nil, configuration: configuration)
        completion(entry)
    }

    public func timeline(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, title: "iOS 14 Review", author: "Federico Viticci", blog: "MacStories", image: nil, imageURL: nil, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
   
    }
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
    public let title: String
    public let author: String
    public let blog: String
    public let image: Image?
    public let imageURL: URL?
    public let configuration: ConfigurationIntent
}

struct PlaceholderView : View {
    var body: some View {
        VStack {
            Text("Article Title")
                .font(.subheadline)
            HStack {
                Text("Author")
                Text(" - ")
                Text("Blog")
            }
        }
    }
}

struct UnreadsWidgetEntryView : View {
    var entry: Provider.Entry
    var entries: [Provider.Entry]?

    var body: some View {
        
        LazyVStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, pinnedViews: /*@START_MENU_TOKEN@*/[]/*@END_MENU_TOKEN@*/, content: {
            ForEach(1...2, id: \.self) { count in
                
                VStack {
                    Text(entry.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .alignmentGuide(HorizontalAlignment.leading) { _ in 0}
                    HStack {
                        Text(entry.author)
                        Text("-")
                        Text(entry.blog)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .alignmentGuide(HorizontalAlignment.leading) { _ in 0}
                }
                .alignmentGuide(VerticalAlignment.top) { _ in 0 }
                .alignmentGuide(HorizontalAlignment.leading) { _ in 0}
                
            }
        })
        .alignmentGuide(.leading, computeValue: { dimension in
            16
        })
        .alignmentGuide(.top, computeValue: { dimension in
            16
        })
        
    }
}

@main
struct UnreadsWidget: Widget {
    private let kind: String = "UnreadsWidget"

    public var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            UnreadsWidgetEntryView(entry: SimpleEntry(date: Date(), title: "Article Title", author: "Author", blog: "Blog", image: nil, imageURL: nil, configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .configurationDisplayName("Unread Articles")
        .description("Latest unread articles from your account.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct UnreadsWidget_Previews: PreviewProvider {
    static var previews: some View {
        UnreadsWidgetEntryView(entry: SimpleEntry(date: Date(), title: "Article Title", author: "Author", blog: "Blog", image: nil, imageURL: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
