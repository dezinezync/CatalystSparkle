//
//  UnreadsWidget.swift
//  UnreadsWidget
//
//  Created by Nikhil Nigade on 29/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import WidgetKit
import SwiftUI

struct UnreadsProvider: IntentTimelineProvider {
   
    func loadData (name: String) -> SimpleEntries? {
        
        let json: SimpleEntries
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                do {
                    
                    let decoder = JSONDecoder();
                    
                    json = try decoder.decode(SimpleEntries.self, from: data)
                    
                    return json
                }
                catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
        
        return nil
        
    }
    
    public func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntries) -> Void) {
    
        if let jsonData = loadData(name: "articles.json") {
            
            return completion(jsonData)
            
        }
        
    }
    
    public func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntries>) -> Void) {
        
        if let jsonData = loadData(name: "articles.json") {
        
            var entries: [SimpleEntries] = []
            
            entries.append(jsonData)
            
            let timeline = Timeline(entries: entries, policy: .never)
            
            completion(timeline)
            
        }

    }
    
    func placeholder(in context: Context) -> SimpleEntries {
        
        if let jsonData = loadData(name: "articles.json") {
            
            return jsonData;
            
        }
        
        let entryCol = SimpleEntries(date: Date(), entries: []);
        
        return entryCol
        
    }
    
}

struct SimpleEntry: TimelineEntry, Hashable, Identifiable, Decodable {
    
    public let date: Date
    public let title: String
    public let author: String
    public let blog: String
    public let imageURL: String?
    public let image: String?
    public let identifier: Int
    public let blogID: Int
    public let favicon: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    var id : Int {
        return hashValue
    }
    
}

struct SimpleEntries: TimelineEntry, Decodable {
    public let date: Date
    public let entries: [SimpleEntry]
}

struct PlaceholderView : View {
    
    var body: some View {
        
        ArticleView(entry: SimpleEntry(date: Date(), title: "Placeholder title", author: "Author", blog: "Blog", imageURL: nil, image: nil, identifier: 0, blogID: 0, favicon: ""))
        .redacted(reason: .placeholder)
        
    }
    
}

struct ArticleView : View {
    
    var entry: SimpleEntry
    
    var body: some View {
        
        Link(destination:URL(string: "elytra://feed/\(entry.blogID)/article/\(entry.identifier)")!) {
            
            ZStack {
            
                HStack(alignment: .center, spacing: 12) {
                    
                    if entry.favicon != nil {
                        
                        let imageData = NSData(base64Encoded: entry.favicon!, options: .ignoreUnknownCharacters)
                        
                        if imageData != nil, let image = UIImage(data: imageData! as Data) {
                                
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 24, maxHeight: 24, alignment: .center)
                                .clipped()
                                .cornerRadius(3.0)
                                .background(Color(UIColor.systemBackground))
                                .alignmentGuide(VerticalAlignment.top) { _ in 0 }
                            
                        }
                        else {
                            
                            Image(systemName: "sqaure.dashed")
                                .frame(maxWidth: 24, maxHeight: 24, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                        }
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Text(entry.title)
                            .font(Font.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            .lineLimit(2)
                        
                        Text("\(entry.author) - \(entry.blog)")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }

                    }
                    
                    Spacer()
                    
                    if entry.image != nil {
                        
                        let imageData = NSData(base64Encoded: entry.image!, options: .ignoreUnknownCharacters)
                        
                        if let image = UIImage(data: imageData! as Data) {
                                
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 44, maxHeight: 44, alignment: .center)
                                .cornerRadius(6.0)
                                .background(Color(UIColor.systemBackground))
                            
                        }
                        else {
                            
                            Image(systemName: "sqaure.dashed")
                                .frame(maxWidth: 24, maxHeight: 24, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                        }

                    }
                    
                }
                
            }
            
        }
        
    }
        
}

struct UnreadsWidgetEntryView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entries: SimpleEntries

    var body: some View {
        
        ZStack {
            
            VStack (alignment: .leading, spacing: (widgetFamily == .systemMedium ? 4 : 8)) {
                
                Text("Recent Unreads")
                    .font(Font.title3.bold())
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
                            ForEach(0..<[entries.entries.count, 5].min()!, id: \.self) { count in
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

struct UnreadsWidget: Widget {
    
    private let kind: String = "UnreadsWidget"

    public var body: some WidgetConfiguration {
        
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: UnreadsProvider()) { entries in
                UnreadsWidgetEntryView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .configurationDisplayName("Unread Articles")
        .description("Latest unread articles from your account.")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
    
}

#if DEBUG

struct UnreadsWidget_Previews: PreviewProvider {

    static var previews: some View {
        
        let entry1 = SimpleEntry(date: Date(), title: "Apple releases second macOS Big Sur public beta", author: "Michael Potuck", blog: "9to5Mac", imageURL: "https://9to5mac.com/wp-content/uploads/sites/6/2020/07/macOS-Big-Sur-changes-and-features.jpg?quality=82&strip=all&w=1600", image: nil, identifier: 15930957, blogID: 19, favicon: "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")
        
        let entry3 = SimpleEntry(date: Date(), title: "Ghost Cruise Ships ∞", author: "Paul Kafasis", blog: "One Foot Tsunami", imageURL: "https://ichef.bbci.co.uk/news/976/cpsprodpb/B669/production/_113879664_hi061524349.jpg", image: nil, identifier: 15930980, blogID: 336, favicon: nil)
        
        let entry2 = SimpleEntry(date: Date(), title: "Apple hits $2 trillion – a record-breaking market cap milestone", author: "Tom Rolfe", blog: "TapSmart", imageURL: nil, image: nil, identifier: 15916691, blogID: 5959, favicon: nil)
        
        let json = SimpleEntries(date: Date(), entries: [entry1, entry2, entry3])
        
        UnreadsWidgetEntryView(entries: json)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Unreads Large")

        UnreadsWidgetEntryView(entries: json)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Unreads Medium")
            .environment(\.colorScheme, .dark)
        
        let emptyEntries = SimpleEntries(date: Date(), entries: [])
        
        UnreadsWidgetEntryView(entries:emptyEntries)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Unreads Medium")
            .environment(\.colorScheme, .dark)

    }

}

#endif

/* Bundler */
@main
struct ElytraWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        UnreadsWidget()
        CountersWidget()
    }
}
