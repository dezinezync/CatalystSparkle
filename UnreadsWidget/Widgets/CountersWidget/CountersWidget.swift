//
//  CountersWidget.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 20/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit

struct CountersProvider: TimelineProvider {
    
    func loadData (name: String) -> CountersEntry? {
        
        let json: CountersEntry
        
        if let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.elytra") {
                
            let fileURL = baseURL.appendingPathComponent(name)
                
            if let data = try? Data(contentsOf: fileURL) {
                // we're OK to parse!
                do {
                    
                    let decoder = JSONDecoder();
                    
                    json = try decoder.decode(CountersEntry.self, from: data)
                    
                    return json
                }
                catch {
                    print(error.localizedDescription)
                }
                
            }
            
        }
        
        return nil
        
    }
    
    func placeholder(in context: Context) -> CountersEntry {
        CountersEntry(date: Date(), unread: 25, today: 12, bookmarks: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountersEntry) -> ()) {
        
        if let jsonData = loadData(name: "counters.json") {
            
            completion(jsonData)
            
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CountersEntry] = []
        
        if let jsonData = loadData(name: "counters.json") {
            
            entries.append(jsonData)
            
        }

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct CountersView : View {
    
    var entry : CountersEntry
    
    var body: some View {
        
        ZStack {
            
            VStack(alignment:.leading, spacing: 12) {
                
                HStack(alignment:.center) {
                    
                    Image(systemName: "largecircle.fill.circle")
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 24, height: 24, alignment: .center)
                    
                    Text(String(entry.unread))
                        .font(Font.title2.bold())
                        .foregroundColor(Color(UIColor.systemBlue))
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                                        
                }
                
                HStack(alignment: .center) {
                    
                    Image(systemName: "calendar")
                        .foregroundColor(Color(UIColor.systemRed))
                        .frame(width: 24, height: 24, alignment: .center)
                    
                    Text(String(entry.today))
                        .font(Font.title2.bold())
                        .foregroundColor(Color(UIColor.systemRed))
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                                        
                }
                
                HStack(alignment: .center) {
                    
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(Color(UIColor.systemOrange))
                        .frame(width: 24, height: 24, alignment: .center)
                    
                    Text(String(entry.bookmarks))
                        .font(Font.title2.bold())
                        .foregroundColor(Color(UIColor.systemOrange))
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                                        
                }
                
            }
            .frame(maxWidth: .infinity)
                    
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        
    }
    
}

struct CountersEntry: TimelineEntry, Decodable {
    let date: Date
    let unread: Int
    let today: Int
    let bookmarks: Int
}

struct CountersWidgetEntryView : View {
    
    var entry: CountersProvider.Entry

    var body: some View {
        
        CountersView(entry: entry)
            .background(Color(UIColor.systemBackground))
        
    }
    
}

struct CountersWidget: Widget {
    let kind: String = "CountersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountersProvider()) { entry in
            CountersWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Elytra - Counters")
        .description("Glance at unread articles and articles from today counters.")
        .supportedFamilies([.systemSmall])
    }
}


#if DEBUG

struct CountersWidget_Previews: PreviewProvider {
    static var previews: some View {
        
        CountersWidgetEntryView(entry: CountersEntry(date: Date(), unread: 25, today: 12, bookmarks: 8))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .light)
        
        CountersWidgetEntryView(entry: CountersEntry(date: Date(), unread: 25, today: 12, bookmarks: 8))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
        
    }
}

#endif
