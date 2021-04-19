//
//  BloccsWidget.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI
import WidgetKit
import Models

struct BloccsWidget: Widget {

    private let kind: String = "Bloccs Widget"
    
    public var body: some WidgetConfiguration {
        
        IntentConfiguration(
            kind: kind,
            intent: BloccsIntent.self,
            provider: BloccsProvider()) { entries in
            
            BloccsGridView(entries: entries)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
        }
        .configurationDisplayName("Bloccs - Unreads")
        .description("Latest unread articles as bloccs")
        .supportedFamilies([.systemMedium, .systemLarge])
        
    }
    
}

#if DEBUG

let previewData: UnreadEntries = {
   
    let entry1 = WidgetArticle()
    entry1.feedID = 19
    entry1.identifier = "15930957"
    entry1.title = "Apple releases second macOS Big Sur public beta"
    entry1.author = "Michael Potuck"
    entry1.blog = "9to5Mac"
    entry1.coverImage = URL(string:"https://images.weserv.nl/?url=https://9to5mac.com/wp-content/uploads/sites/6/2020/07/macOS-Big-Sur-changes-and-features.jpg?quality=82&strip=all&w=300&filename=bigsur@3x.png&we")
    entry1.favicon = URL(string: "https://images.weserv.nl/?url=https://9to5mac.com/apple-touch-icon-180x180.png&w=128&dpr=3&output=&q=0.8&filename=9to5favicon@3x.png&we")
    
    let entry2 = WidgetArticle()
    entry2.feedID = 336
    entry2.identifier = "15930980"
    entry2.title = "How This iPhone Got FIXED!"
    entry2.author = "Linus Tech Tips"
    entry2.blog = "Linus Tech Tips"
    entry2.coverImage = URL(string:"https://images.weserv.nl/?url=https://i2.ytimg.com/vi/u1MNgP3LFM4/hqdefault.jpg&w=160&dpr=3&output=jpg&q=0.800000011920929&filename=hqdefault@3x.jpg&we")
    entry2.favicon = URL(string: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo@3x.&we")
    
    let entry3 = WidgetArticle()
    entry3.feedID = 12388
    entry3.identifier = "25425066"
    entry3.title = "I Finally Started a Mac Channel.... - WAN Show April 16, 2021"
    entry3.author = "Linus Tech Tips"
    entry3.blog = "Linus Tech Tips"
    entry3.coverImage = URL(string:"https://images.weserv.nl/?url=https://i2.ytimg.com/vi/U8J5DwHDbGA/hqdefault.jpg?quality=82&strip=all&w=300&filename=hqdefault@3x.png&we")
    entry3.favicon = URL(string: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo@3x.&we")
    
    let entry4 = WidgetArticle()
    entry4.feedID = 84
    entry4.identifier = "25347528"
    entry4.title = "Sheet Pan Shrimp and Cauli Rice"
    entry4.author = "Lindsay"
    entry4.blog = "Pinch of Yum"
    entry4.coverImage = URL(string:"https://images.weserv.nl/?url=https://pinchofyum.com/wp-content/uploads/Sheet-Pan-Shrimp-and-Cauli-Rice-4-183x183.jpg&w=160&dpr=3&output=jpg&q=0.800000011920929&filename=Sheet-Pan-Shrimp-and-Cauli-Rice-4-183x183@3x.jpg&we")
    entry4.favicon = URL(string: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU_Qw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJzGUJdH8PJ5d34Uk6CYZmAMWtam2Cpk6tU@3x.jpg&we")
    
    let entry5 = WidgetArticle()
    entry5.feedID = 3735
    entry5.identifier = "25352919"
    entry5.title = "The Man In The Hat"
    entry5.author = ""
    entry5.blog = "Latest Movie Trailers"
    entry5.coverImage = URL(string:"http://trailers.apple.com/trailers/independent/the-man-in-the-hat/images/background_2x.jpg?quality=82&strip=all&w=300&filename=background_2x@3x.png&we")
    entry5.favicon = URL(string: "https://images.weserv.nl/?url=https://storage.googleapis.com/site-assets/JKJ84zVGtgLx88U1BUtB_OHJOGqCarxS2l9ocVPDdtw_visual-16d0ae2740c&w=128&dpr=3&output=&q=0.800000011920929&filename=JKJ84zVGtgLx88U1BUt@3xjpg.&we")
    
    let entry6 = WidgetArticle()
    entry6.feedID = 12389
    entry6.identifier = "25340935"
    entry6.title = "50 PC Build Tips in Under 10 Minutes"
    entry6.author = "Optimum Tech"
    entry6.blog = "Optimum Tech"
    entry6.coverImage = URL(string:"https://images.weserv.nl/?url=https://i1.ytimg.com/vi/DEA0_upu4sQ/hqdefault.jpg&w=160&dpr=3&output=jpg&q=0.800000011920929&filename=background_2x@3x.jpg&we")
    entry6.favicon = URL(string: "https://images.weserv.nl/?url=https://yt3.ggpht.com/a/AATXAJwVudGxH5JeOYJcVACv-8LFUlSchbH5zMuyf5VUZw=s900-c-k-c0xffffffff-no-rj-mo&w=128&dpr=3&output=&q=0.800000011920929&filename=AATXAJwVudGxH5JeOYJcVACv@3x.jpg&we")
    
    let data = UnreadEntries(date: Date(), entries: [entry1, entry2, entry3, entry4, entry5, entry6])
    
    return data
    
}()

struct Bloccs_Previews: PreviewProvider {
    
    static var previews: some View {

        BloccsGridView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.colorScheme, .light)
        
        BloccsGridView(entries: previewData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
        

    }

}

#endif
