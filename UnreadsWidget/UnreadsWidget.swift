//
//  UnreadsWidget.swift
//  UnreadsWidget
//
//  Created by Nikhil Nigade on 29/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import WidgetKit
import SwiftUI
import SDWebImageSwiftUI

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
    
    public func snapshot(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (SimpleEntries) -> ()) {
        
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
    public let identifier: Int
    public let blogID: Int
    
    var hashValue : Int {
        return title.hashValue
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
        
        ArticleView(entry: SimpleEntry(date: Date(), title: "Placeholder title", author: "Author", blog: "Blog", imageURL: nil, identifier: 0, blogID: 0))
        .redacted(reason: .placeholder)
        
    }
    
}

struct ArticleView : View {
    
    var entry: SimpleEntry
    
    var body: some View {
        
        Link(destination:URL(string: "elytra://feed/\(entry.blogID)/article/\(entry.identifier)")!) {
            
            ZStack {
            
                HStack(alignment: .center, spacing: 12) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        Text(entry.title)
                            .font(Font.subheadline.weight(.medium))
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
                    
                    if entry.imageURL != nil {
                        
                        WebImage(url: URL(string: entry.imageURL!))
                            .placeholder(Image(systemName: "square.dashed"))
                            .resizable()
                            .frame(maxWidth: 44, maxHeight: 44, alignment: .trailing)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .cornerRadius(3.0)
                            .background(Color(UIColor.secondarySystemFill))
                        
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
            
            VStack (alignment: .leading, spacing: 8) {
                
                Text("Recent Unreads")
                    .font(Font.title3.bold())
                    .foregroundColor(Color(UIColor.systemIndigo))
                    .multilineTextAlignment(.leading)
                
                if (widgetFamily == .systemMedium) {
                    
                    LazyVStack(alignment: .leading, spacing: 4, pinnedViews: [], content: {
                        ForEach(0..<[entries.entries.count, 2].min()!, id: \.self) { count in
                            ArticleView(entry: entries.entries[count])
                        }
                    })
                    
                }
                else {
                    
                    LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [], content: {
                        ForEach(0..<[entries.entries.count, 6].min()!, id: \.self) { count in
                            ArticleView(entry: entries.entries[count])
                        }
                    })
                    .alignmentGuide(.top) { _ in 0 }
                    
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
        
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: UnreadsProvider()) { entries in
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
        
        let entry1 = SimpleEntry(date: Date(), title: "IBM settles LA lawsuit over The Weather Channel app selling user location data", author: "Ben Lovejoy", blog: "9to5Mac", imageURL: "https://9to5mac.com/wp-content/uploads/sites/6/2020/08/The-Weather-Channel-app-selling-user-location-data.jpg?quality=82&strip=all&w=1500", identifier: 15916618, blogID: 19)
        
        let entry2 = SimpleEntry(date: Date(), title: "Tips for searching and saving searches in Mail on Mac", author: "Sandy Writtenhouse", blog: "iDownloadBlog.com", imageURL: "https://media.idownloadblog.com/wp-content/uploads/2020/07/Mac-Mail-Search-Apple-Arcade.jpg", identifier: 15916813, blogID: 12596)
        
        let entry3 = SimpleEntry(date: Date(), title: "Apple hits $2 trillion – a record-breaking market cap milestone", author: "Tom Rolfe", blog: "TapSmart", imageURL: nil, identifier: 15916691, blogID: 5959)
        
        let entries = SimpleEntries(date: Date(), entries: [entry1, entry2, entry3])
        
        UnreadsWidgetEntryView(entries:entries)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Unreads Large")

        UnreadsWidgetEntryView(entries:entries)
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
