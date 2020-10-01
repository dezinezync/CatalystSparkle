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

extension Text {
    
    func platformTitleFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.headline).fontWeight(.bold)
        #elseif canImport(UIKit)
        return self.font(.subheadline).fontWeight(.semibold)
        #else
        return self;
        #endif
        
    }
    
}

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
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: SimpleEntry
    
    var body: some View {
        
        Link(destination:URL(string: "elytra://feed/\(entry.blogID)/article/\(entry.identifier)")!) {
            
            let maxDim : CGFloat = widgetFamily == .systemLarge ? 64 : 46;
            
            ZStack {
            
                HStack(alignment: .top, spacing: 12) {
                    
                    if entry.favicon != nil {
                        
                        WebImage(url: URL(string: entry.favicon!))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 24, maxHeight: 24, alignment: .center)
                            .clipped()
                            .cornerRadius(3.0)
                            .background(Color(.systemBackground))
                            .alignmentGuide(VerticalAlignment.top) { _ in -4 }
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        
                        Text(entry.title)
                            .platformTitleFont()
                            .foregroundColor(.primary)
                            .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            .lineLimit(2)
                        
                        if (entry.author == entry.blog) {
                            
                            Text(entry.blog)
                                .lineLimit(1)
                                .font(Font.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            
                        }
                        else {
                            
                            Text("\(entry.author) - \(entry.blog)")
                                .lineLimit(1)
                                .font(Font.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .alignmentGuide(HorizontalAlignment.leading) { _ in 0 }
                            
                        }
                        
                    }
                    
                    Spacer(minLength: 4)
                    
                    if entry.imageURL != nil {
                        
                        WebImage(url: URL(string: entry.imageURL!))
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
                            ForEach(0..<[entries.entries.count, 4].min()!, id: \.self) { count in
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
        
        let entry1 = SimpleEntry(date: Date(), title: "Apple releases second macOS Big Sur public beta", author: "Michael Potuck", blog: "9to5Mac", imageURL: "https://9to5mac.com/wp-content/uploads/sites/6/2020/07/macOS-Big-Sur-changes-and-features.jpg?quality=82&strip=all&w=1600", image: nil, identifier: 15930957, blogID: 19, favicon: nil)
        
        let entry3 = SimpleEntry(date: Date(), title: "How This iPhone Got FIXED!", author: "", blog: "Linus Tech Tips", imageURL: "https://images.weserv.nl/?url=https://i2.ytimg.com/vi/u1MNgP3LFM4/hqdefault.jpg&w=160&dpr=3&output=jpg&q=0.800000011920929&filename=hqdefault.@3x.jpg&we", image: nil, identifier: 15930980, blogID: 336, favicon: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo@3x.&we")
        
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
