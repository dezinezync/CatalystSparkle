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

extension Text {
    
    func platformTitleFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 14)).fontWeight(.semibold)
        #elseif canImport(UIKit)
        return self.font(.system(size: 15)).fontWeight(.medium)
        #else
        return self;
        #endif
        
    }
    
    func platformBodyFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 14)).fontWeight(.regular)
        #elseif canImport(UIKit)
        return self.font(.system(size: 15)).fontWeight(.regular)
        #else
        return self;
        #endif
        
    }
    
    func platformCaptionFont () -> Text {
        
        #if canImport(AppKit) || targetEnvironment(macCatalyst)
        return self.font(.system(size: 13)).fontWeight(.bold)
        #elseif canImport(UIKit)
        return self.font(.system(size: 13)).fontWeight(.semibold)
        #else
        return self;
        #endif
        
    }
    
}

typealias LoadImagesCompletionBlock = () -> Void

private func loadImagesDataFromPackage (package: SimpleEntries, completion: LoadImagesCompletionBlock? = nil) {
    
    let imageRequestGroup = DispatchGroup()
    
    for entry in package.entries {
        
        if (entry.showFavicon == true && entry.favicon != nil && entry.favicon?.absoluteString != "") {
            
            imageRequestGroup.enter()
            
            SDWebImageManager.shared.loadImage(with: entry.favicon, options: .highPriority, progress: nil) { (image: UIImage?, _: Data?, error: Error?, _: SDImageCacheType, _: Bool, _: URL?) in
                
                imageRequestGroup.leave()
                
            }
            
        }
        
        if (entry.showCover == true && entry.coverImage != nil) {
            
            imageRequestGroup.enter()
            
            SDWebImageManager.shared.loadImage(with: entry.coverImage, options: .highPriority, progress: nil) { (image: UIImage?, _: Data?, error: Error?, _: SDImageCacheType, _: Bool, _: URL?) in
                
                imageRequestGroup.leave()
                
            }
            
        }
        
    }
    
    imageRequestGroup.notify(queue: .main) {
        completion!()
    }
    
}

struct UnreadsProvider: IntentTimelineProvider {
   
    func loadData (name: String, configuration: UnreadsIntent) -> SimpleEntries? {
        
        var json: SimpleEntries
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                do {
                    
                    let decoder = JSONDecoder();
                    
                    let entries: [WidgetArticle] = try decoder.decode([WidgetArticle].self, from: data)
                    
                    let showFavicons: Bool = configuration.showFavicons?.boolValue ?? true
                    let showCovers: Bool = configuration.showCovers?.boolValue ?? true
                    
                    for index in 0..<entries.count {
                        
                        if showFavicons == false {
                                
                            entries[index].showFavicon = false
                            
                        }
                        
                        if showCovers == false {
                                
                            entries[index].showCover = false
                            
                        }
                        
                    }
                    
                    json = SimpleEntries(date: Date(), entries: entries)
                    
                    return json
                }
                catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
        
        return nil
        
    }
    
    public func getSnapshot(for configuration: UnreadsIntent, in context: Context, completion: @escaping (SimpleEntries) -> Void) {
    
        if let jsonData: SimpleEntries = loadData(name: "articles.json", configuration: configuration) {
            
            if (configuration.showFavicons?.boolValue == false) {
                    
                for item in jsonData.entries {
                    
                    if (item.favicon != nil) {
                        item.favicon = nil
                    }
                    
                }
                
            }
            
            if (configuration.showCovers?.boolValue == false) {
                    
                for item in jsonData.entries {
                    
                    if (item.coverImage != nil) {
                        item.coverImage = nil
                    }
                    
                }
                
            }
            
            loadImagesDataFromPackage(package: jsonData) {
                
                completion(jsonData)
                
            }
            
        }
        
    }
    
    public func getTimeline(for configuration: UnreadsIntent, in context: Context, completion: @escaping (Timeline<SimpleEntries>) -> Void) {
        
        if let jsonData = loadData(name: "articles.json", configuration: configuration) {
        
            var entries: [SimpleEntries] = []
            
            entries.append(jsonData)
            
            loadImagesDataFromPackage(package: jsonData) {
                
                let timeline = Timeline(entries: entries, policy: .never)
                
                completion(timeline)
                
            }
            
        }

    }
    
    func placeholder(in context: Context) -> SimpleEntries {
        
        if let jsonData = loadData(name: "articles.json", configuration: UnreadsIntent()) {
            
            return jsonData;
            
        }
        
        let entryCol = SimpleEntries(date: Date(), entries: []);
        
        return entryCol
        
    }
    
}

struct SimpleEntries: TimelineEntry, Decodable {
    public let date: Date
    public var entries: [WidgetArticle]
}

struct PlaceholderView : View {
    
    var body: some View {
        
        WidgetArticleView(entry: WidgetArticle())
        .redacted(reason: .placeholder)
        
    }
    
}

struct WidgetArticleView : View {
    
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

struct UnreadsWidgetEntryView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entries: SimpleEntries

    var body: some View {
        
        ZStack {
            
            VStack (alignment: .leading, spacing: (widgetFamily == .systemMedium ? 4 : 8)) {
                
                Text("Recent Unreads")
                    .font(.system(size: 17)).fontWeight(.bold)
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
                                WidgetArticleView(entry: entries.entries[count])
                            }
                        })
                        
                    }
                    else {
                        
                        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [], content: {
                            ForEach(0..<[entries.entries.count, 4].min()!, id: \.self) { count in
                                WidgetArticleView(entry: entries.entries[count])
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
            intent: UnreadsIntent.self,
            provider: UnreadsProvider()) { entries in
                UnreadsWidgetEntryView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .configurationDisplayName("Unread WidgetArticles")
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
        CountersWidget()
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
//        let json = SimpleEntries(date: Date(), entries: [entry1, entry2, entry3])
//
//        UnreadsWidgetEntryView(entries: json)
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            .previewDisplayName("Unreads Large")
//
//        UnreadsWidgetEntryView(entries: json)
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDevice("Mac Catalyst")
//            .previewDisplayName("Unreads Medium")
//            .environment(\.colorScheme, .dark)
//
//        let emptyEntries = SimpleEntries(date: Date(), entries: [])
//
//        UnreadsWidgetEntryView(entries:emptyEntries)
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("Unreads Medium")
//            .environment(\.colorScheme, .dark)
//
//    }
//
//}
//
//#endif
