//
//  ContentTests.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
@testable import Models

final class ContentTests: XCTestCase {
    
    static func makeContent() -> Content {
        
        guard let data = contentJSON.data(using: .utf8) else {
            fatalError("Invalid JSON")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            fatalError("Failed to deserialize JSON")
        }
        
        let content = Content(from: json)
        
        return content
        
    }
    
    func testInitFromDict() {
        
        let content = Self.makeContent()

        XCTAssertNotNil(content)
        XCTAssertEqual(content.items?.count ?? 0, 17)
        
    }
    
    func testDictRepresentation() {
        
        let content = Self.makeContent()
        let dict = content.dictionaryRepresentation
        
        for name in Content.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if key == "items" || key == "ranges" {
                continue
            }
            
            let a = content.value(for: key) as? AnyHashable
            let b = dict[key] as? AnyHashable
            
            XCTAssertEqual(a, b)
            
        }
        
        let subContent = content.items!.first!
        let subDict = subContent.dictionaryRepresentation
        
        for name in Content.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if key == "ranges" {
                continue
            }
            
            let a = subContent.value(for: key) as? AnyHashable
            let b = subDict[key] as? AnyHashable
            
            print("\(key)\n\(String(describing: a)) \(String(describing: b))")
            
            XCTAssertEqual(a, b)
            
        }
        
    }
    
    func testDescription() {
        
        let content = Self.makeContent()
        let description = content.description
        
        XCTAssert(description.contains("Content: 0x"))
        
    }
    
    func testModelWithImagesKey () {
        
        guard let data = imagesJSON.data(using: .utf8) else {
            fatalError("Invalid JSON")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            fatalError("Failed to deserialize JSON")
        }
        
        let content = Content(from: json)
        
        guard let items = content.items else {
            fatalError("No items assigned from JSON")
        }
        
        guard let item = items.first(where: { (content) -> Bool in
            return content.images != nil && (content.images?.count ?? 0) > 0
        }) else {
            fatalError("Content with non-nil images key not found")
        }
        
        guard let images = item.images else {
            fatalError("Expected to find images in item")
        }
        
        XCTAssertEqual(images.count, 2)
        
        let image = images.first!
        
        XCTAssertEqual(image.type, "image")
        XCTAssertEqual(image.url?.absoluteString, "https://blog.architizer.com/wp-content/uploads/15300200084092-1-scaled.jpg")
        
    }
    
    func testUndefinedKey () {
        
        let content = Self.makeContent()
        content.setValue(true, forUndefinedKey: "foo")
        content.setValue(true, forUndefinedKey: "bar")
        
    }
    
    func testSettingRangesAsDict () {
        
        let content = Self.makeContent()
        let item = content.items!.first!
        
        item.setValue([
            "name": "link",
            "range": "0,25",
            "url": "https://elytra.app"
        ], forKey: "ranges")
        
    }
    
    func testSettingImagesAsDict () {
        
        let item = Content()
        
        item.setValue([
            "type": "image",
            "alt": "Elytra Favicon",
            "url": "https://elytra.app/favicon.png",
            "attributes": [
                "sizes": "32,32"
            ],
            "size": "32,32"
        ], forKey: "images")
        
        XCTAssertNotNil(item.images)
        XCTAssertEqual(item.images?.count ?? 0, 1)
        
    }
    
    func testSettingImagesAsArray () {
        
        let item = Content()
        
        let arr = [
            [
                "type": "image",
                "alt": "Elytra Favicon",
                "url": "https://elytra.app/favicon.png",
                "attributes": [
                    "sizes": "32,32"
                ],
                "size": "32,32"
            ],
            [
                "type": "image",
                "alt": "Elytra Favicon",
                "url": "https://elytra.app/favicon.png",
                "attributes": [
                    "sizes": "32,32"
                ],
                "size": "32,32"
            ]
        ]
        
        item.setValue(arr, forKey: "images")
        
        XCTAssertNotNil(item.images)
        XCTAssertEqual(item.images?.count ?? 0, 2)
        
    }
    
    func testSettingImagesAsContent () {
        
        let item = Content()
        
        item.setValue(Content(from: [
            "type": "image",
            "alt": "Elytra Favicon",
            "url": "https://elytra.app/favicon.png",
            "attributes": [
                "sizes": "32,32"
            ],
            "size": "32,32"
        ]), forKey: "images")
        
        XCTAssertNotNil(item.images)
        XCTAssertEqual(item.images?.count ?? 0, 1)
        
    }
    
    func testSettingImagesAsArrayOfContent () {
        
        let item = Content()
        
        let arr = [
            [
                "type": "image",
                "alt": "Elytra Favicon",
                "url": "https://elytra.app/favicon.png",
                "attributes": [
                    "sizes": "32,32"
                ],
                "size": "32,32"
            ],
            [
                "type": "image",
                "alt": "Elytra Favicon",
                "url": "https://elytra.app/favicon.png",
                "attributes": [
                    "sizes": "32,32"
                ],
                "size": "32,32"
            ]
        ].map { Content(from: $0) }
        
        item.setValue(arr, forKey: "images")
        
        XCTAssertNotNil(item.images)
        XCTAssertEqual(item.images?.count ?? 0, 2)
        
    }
    
    func testSettingRangesAsRange () {
        
        let content = Content()
        content.setValue(ContentRange(from: [
            "element": "heading",
            "level": 1,
            "range": "0,25"
        ]), forKey: "ranges")
        
        XCTAssertNotNil(content.ranges)
        XCTAssertEqual(content.ranges.count, 1)
        XCTAssertEqual(content.ranges.first?.range.location, 0)
        XCTAssertEqual(content.ranges.first?.range.length, 25)
        
    }
    
    func testSettingRangesAsRanges () {
        
        let content = Content()
        
        let ranges = [
            ContentRange(from: [
                "element": "heading",
                "level": 1,
                "range": "0,25"
            ]),
            ContentRange(from: [
                "element": "heading",
                "level": 2,
                "range": "0,20"
            ])
        ]
        
        content.setValue(ranges, forKey: "ranges")
        
        XCTAssertNotNil(content.ranges)
        XCTAssertEqual(content.ranges.count, 2)
        XCTAssertEqual(content.ranges.first?.range.location, 0)
        XCTAssertEqual(content.ranges.first?.range.length, 25)
        XCTAssertEqual(content.ranges.last?.range.location, 0)
        XCTAssertEqual(content.ranges.last?.range.length, 20)
        
    }
    
    func testSettingInvalidSize () {
        
        let content = Content()
        content.setValue("1,", forKey: "size")
        
        XCTAssertEqual(content.size, nil)
        
    }
    
    func testSettingValidSize () {
        
        let content = Content()
        content.setValue(CGSize(width: 32, height: 32), forKey: "size")
        
        XCTAssertEqual(content.size, CGSize(width: 32, height: 32))
        
    }
    
    func testSettingItemsAsItem () {
        
        let content = Content()
        content.setValue(Content(), forKey: "items")
        
        XCTAssertNotNil(content.items)
        XCTAssertEqual(content.items?.count ?? 0, 1)
        
    }
    
    func testSettingItemsAsItems () {
        
        let content = Content()
        content.setValue([Content(), Content()], forKey: "items")
        
        XCTAssertNotNil(content.items)
        XCTAssertEqual(content.items?.count ?? 0, 2)
        
    }
    
}

private let contentJSON = "[{\"node\":\"paragraph\",\"content\":\"The Winter 2020 update is finally ready in 2021! This is the first release of Elytra which brings local sync, local notifications and a lot of performance and stability improvements to the apps.\",\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Similar to Elytra v2 and v2.1, this is an iOS 14 only release. The latest supported version for iOS 13 is v1.8 and will be deprecated soon.\",\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"You can download the update from the App Store. If you feel generous and have a couple of minutes, please leave a review on the App Store. It makes a huge difference for me. Thank you in advance.\",\"ranges\":[{\"element\":\"anchor\",\"range\":\"37,9\",\"url\":\"https://apps.apple.com/us/app/id1433266971\"}]},{\"node\":\"header\",\"level\":2,\"content\":\"Local Sync\",\"ranges\":[],\"id\":\"localsync\"},{\"node\":\"image\",\"url\":\"https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2.png\",\"size\":\"890,418/\",\"attr\":{\"alt\":\"Elytra v2.2 running on Macbook Air, iPhone XS and iPad Air\"},\"srcset\":{\"2x\":\"https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-768w@2x.png\",\"1x\":\"https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2-480w.png\"}},{\"type\":\"paragraph\",\"content\":\"This release brings Local Sync to the apps. Local Sync caches all articles across all your feeds (just like other RSS Feed Reader Apps). This is not a \"},{\"node\":\"em\",\"content\":\"“new”\",\"ranges\":[]},{\"type\":\"paragraph\",\"content\":\" technique. Feed Reader apps have been doing this for as long as I can remember. Elytra now uses the same technique by leveraging its APIs to make the entire process a lot faster!\"},{\"node\":\"paragraph\",\"content\":\"Elytra does not have to check every single feed if it has new updates. It uses a single API to check if updates are present, and if they are, sync them to your devices.\",\"ranges\":[]},{\"node\":\"header\",\"level\":2,\"content\":\"Full Change Log\",\"ranges\":[],\"id\":\"fullchangelog\"},{\"node\":\"header\",\"level\":3,\"content\":\"New\",\"ranges\":[],\"id\":\"new\"},{\"node\":\"ul\",\"content\":[{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Local Sync. All feeds are now synced to your device locally, so you can continue reading even when your device is offline.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Added a new “Title View” to individual feeds. Open a feed and tap on its title. This shows the Feed Info and two preferences at the moment: Push/Local Notifications & Safari Reader Mode. These are per feed settings. This is very similar to the design and functionality from \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"NetNewsWire\",\"ranges\":[],\"url\":\"https://netnewswire.com\"},{\"node\":\"paragraph\",\"content\":\", is directly inspired by it, but with a minor difference: the layout and copy denotes which feeds support Push Notifications, while the others supporting Local Notifications.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Push Notifications Request Form. If you already have push notifications enabled, you won’t see this. This is per device.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Added support for background push notifications to keep all your devices in sync without needing manual refreshing.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Push Notifications for new articles now download and cache the article for immediate use.\",\"ranges\":[]}]}]},{\"node\":\"header\",\"level\":3,\"content\":\"Improvements\",\"ranges\":[],\"id\":\"improvements\"},{\"node\":\"ul\",\"content\":[{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Tapping on a folder now opens the folder’s feed.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Tapping on the disclosure icon on a folder now toggles its expanded state.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Filtering is now stricter. It’ll match “sponsor” but will not match “sponsored”.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Added Feeds to the iOS Search Index. You can now directly open feeds by their names (or custom names if you have one set).\",\"ranges\":[]}]}]},{\"node\":\"header\",\"level\":3,\"content\":\"Fixes\",\"ranges\":[],\"id\":\"fixes\"},{\"node\":\"ul\",\"content\":[{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed the tint colour for the blog name when opening a micro-blog article.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed adding feed by URL where the feed presents multiple options.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue when searching by title for 3-letter sites like CNN or BBC.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed articles not loading for certain feeds.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed Today View not updating when opened after an app launch.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue with the iPadOS app showing different widths for the columns in different orientations or environments (split view).\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue with the apps not correctly download bookmarks from the API.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue where toggling folders in the sidebar interface would show empty folders.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue with certain CJK paragraph blocks rendering incorrectly when certain linebreak characters are used in the paragraph text.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue with filters incorrectly hiding articles when matching against CJK based filters.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue with line-heights in the articles list for multi-lined article titles with favicons.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue where the “no articles” label would appear over the articles.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed an issue for adding Streaming Video Channel feeds. They recently changed their format which was causing issues.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed a crash when writing the widgets data to disk when the app has just been sent to the background.\",\"ranges\":[]}]},{\"node\":\"li\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Fixed Navigation Bar buttons not appearing in some contexts.\",\"ranges\":[]}]}]},{\"node\":\"paragraph\",\"content\":\"Thank you for reading.\",\"ranges\":[]}]"

let imagesJSON = "[{\"node\":\"paragraph\",\"content\":\"It’s not too late to enter the 9th Annual A+Awards, the world’s largest architectural awards program! Submit your best new projects before April 23rd, 2021 for a shot at international publication and worldwide recognition.\",\"ranges\":[{\"element\":\"em\",\"range\":\"0,222\"},{\"element\":\"anchor\",\"range\":\"31,19\",\"url\":\"https://awards.architizer.com/architecture/awards/?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"anchor\",\"range\":\"102,29\",\"url\":\"https://www.architizerawards.com/a?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"strong\",\"range\":\"139,16\"}]},{\"node\":\"paragraph\",\"content\":\"The Mediterranean has long hosted opportunities for architects to design environments of leisure, from Roman escapes on the Gulf of Baia to Adalberto Libera’s Villa Malaparte on Capri — famously featured in Jean-Luc Goddard’s 1963 film Contempt. These seven homes expand and elaborate on the heritage of the Mediterranean summer holiday.\",\"ranges\":[{\"element\":\"em\",\"range\":\"236,9\"}]},{\"node\":\"paragraph\",\"content\":\"Many utilize plaster, a traditional material in the region that reflects solar heat and helps to cool in the hot months, while others take a more subdued approach with local stone and exposed concrete. Renovations such as Amelia Tavella’s Casa Santa Teresa on the island of Corsica and Rubén Muedra Estudio de Arquitectura’s Dune House demonstrate the possibilities for adapting and preserving modernist vacation getaways for contemporary clients. The unifying theme of these striking residences is an extraordinary sea view and a spectacular coastal setting.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/1585489027959WEB-IMG_9209.jpg\",\"size\":\"2500,1667\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Pool with sea view\"}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-768x512.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-1024x683.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-1536x1024.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-2048x1366.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR.jpg\"},\"size\":\"2500,1667\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"node\":\"a\",\"content\":\"Casa Santa Teresa\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,17\"}],\"url\":\"https://architizer.com/projects/casa-santa-teresa/\"},{\"node\":\"paragraph\",\"content\":\" by AMELIA TAVELLA ARCHITECTES, Ajaccio, France\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"This home on the Corsican coast is designed around natural elements: the sea, flowering bougainvillea, the breeze, and sunlight. Thoughtful features such as pivoting doors and slatted shutters allow the residence to fully open to the climate in summer, adjusting to the light and heat of the day. A pool in the center of a stone terrace directly abuts a sandy beach stretching across the edge of the property. Exterior plaster walls and interior white paint, as well as a wooden brise soliel and interior finishings connect the distinct zones of the project.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-300x158.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-400x210.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-768x403.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-1024x538.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-1536x806.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-2048x1075.jpg\",\"2335\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001.jpg\"},\"size\":\"2335,1226\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2335px)\",\"100vw,\",\"2335px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-768x512.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-1024x683.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-2048x1366.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-scaled.jpg\"},\"size\":\"2560,1708\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"a\",\"content\":\"Dune House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/dune-house-2/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Rubén Muedra Estudio de Arquitectura\",\"ranges\":[],\"url\":\"https://www.rubenmuedra.com/\"},{\"node\":\"paragraph\",\"content\":\", Oliva, Spain\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Crouched behind a dune on the Valencian coast, Dune House is a renovated bunker-like modernist home from the 1940s. The overall profile is squat—a white roofline pressed against the sky, but elevated just enough to offer an uninterrupted view of the Balearic Sea. From the terrace, the panoramic view is framed by a white concrete window, reflected into a swimming pool. The interior is similarly monochrome, with white kitchen cabinets and furniture. Hued sliding glass doors echo the chromatic contrast between the home and the sky.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222.jpeg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-300x200.jpeg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-400x267.jpeg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-768x512.jpeg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-1024x683.jpeg\",\"1344\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222.jpeg\"},\"size\":\"1344,896\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"1344px)\",\"100vw,\",\"1344px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/1563530762118WhatsApp_Image_2018-11-28_at_18.58.15.jpeg\",\"size\":\"1344,896\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Apartment with tiled ceiling\"}},{\"node\":\"a\",\"content\":\"Romantic Nest in Amalfi Coast\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,29\"}],\"url\":\"https://architizer.com/projects/romantic-nest-in-amalfi-coast/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Ernesto Fusco Interior Design\",\"ranges\":[],\"url\":\"https://www.ernestofusco.it/?lang=en\"},{\"node\":\"paragraph\",\"content\":\", Cetara, Italy\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"A traditional product of the Amalfi Coast region is multicolored majolica tile, many produced in the seaside resort of Vietri Sul Mare at the Paolo Soleri-designed Ceramica Solimene factory. Ernesto Fusco’s renovation of a sea-view apartment in the cliffside town of Cetara showcases majolica ceramics in a unique ceiling and kitchen counter splash composed of the colorful tiles. The design is particularly suitable as the apartment’s terrace faces the signature green-and-yellow majolica dome of the local parish.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/1403254290802Int_Ibi_Brigitte_DefR05.jpg\",\"size\":\"6048,4032\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Plaster walls with terrace and pool\"}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/1403254377967Int_Ibi_Brigitte_DefR30.jpg\",\"size\":\"6048,4032\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Apartment interior with contemporary furniture\"}},{\"node\":\"a\",\"content\":\"Dupli Dos\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,9\"}],\"url\":\"https://architizer.com/projects/dupli-dos/\"},{\"node\":\"paragraph\",\"content\":\"by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"JUMA architects\",\"ranges\":[],\"url\":\"https://www.jumaarchitects.com/en\"},{\"node\":\"paragraph\",\"content\":\", Ibiza, Spain\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"JUMA Architects united two holiday apartments into one unit on the Spanish island of Ibiza. This consolidation necessitated the removal of a staircase and the creation of a single outdoor terrace. The resulting patio offers expansive views of the Balearic Sea, disturbed only by interspersed cacti. With its white walls, sea views, and terrace, the home epitomizes the classic Mediterranean holiday escape.\",\"ranges\":[]},{\"node\":\"gallery\",\"images\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-300x212.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-400x283.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-768x543.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-1024x723.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-1536x1085.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-2048x1447.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-scaled.jpg\"},\"size\":\"2560,1809\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-300x240.jpg\",\"376\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-376x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-768x613.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-1024x817.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-1536x1226.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-2048x1635.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-scaled.jpg\"},\"size\":\"2560,2044\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}}]},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/15300200326386.jpg\",\"size\":\"5000,3999\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Concrete portico with pool\"}},{\"node\":\"a\",\"content\":\"Ring House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/ring-house/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Deca Architecture\",\"ranges\":[],\"url\":\"http://decablogs.squarespace.com/new-page-1\"},{\"node\":\"paragraph\",\"content\":\", Agia Galini, Greece\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Ring House is built into a mountainside slope overlooking Messara Bay, with a C-shape that enables it to maintain a low topographic profile. It is composed primarily of two materials: local stone and concrete. Tension between the two creates dramatically different perceptions. Viewed from the pool, the residence is an ultra-modern getaway, whereas from the exterior incline the muted brown stone and grey concrete camouflage into the arid scrubland. To reduce the impact of construction in an ecologically sensitive zone, the architects surveyed and collected seeds from native fauna, then used to restore the landscape that was altered by construction access roads.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-300x240.jpg\",\"375\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-375x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-768x614.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-1024x819.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-1536x1229.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-2048x1639.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-scaled.jpg\"},\"size\":\"2560,2048\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-300x240.jpg\",\"375\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-375x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-768x614.jpg\",\"900\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S.jpg\"},\"size\":\"900,720\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"900px)\",\"100vw,\",\"900px\"]}},{\"node\":\"a\",\"content\":\"villa kget\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/villa-kget/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"bonte et migozzi architectes\",\"ranges\":[],\"url\":\"http://bonte-migozzi.com/\"},{\"node\":\"paragraph\",\"content\":\", Ensuès-la-Redonne, France\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"On account of its narrow plot, villa kget is elevated on stilts to project over the hillside. Mimicking the elongated forms of the stilts, wooden slats encapsulate the residence’s exterior. The interior is similarly replete with wood, a xyloid theme that befits the home’s location amid a coastal Mediterranean pine forest. The tapered interior opens into covered terraces with superb views of the Gulf of Marseille.\",\"ranges\":[]},{\"node\":\"gallery\",\"images\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-768x513.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1024x684.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-2048x1367.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\"},\"size\":\"2500,1669\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"videoID\":\"12345\",\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/154733940285319_Bedrock_House_-_Idis_Turato_-_Turato_Architects__SECTIONS.jpg\",\"size\":\"2500,1869\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Cross-section of home\"}}]},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-768x513.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1024x684.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-2048x1367.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\"},\"size\":\"2500,1669\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"node\":\"a\",\"content\":\"Bedrock House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,13\"}],\"url\":\"https://architizer.com/projects/bedrock-house-2/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Turato Architects / Idis Turato\",\"ranges\":[],\"url\":\"https://idisturato.tumblr.com/\"},{\"node\":\"paragraph\",\"content\":\", Brzac, Croatia\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Composed of two overlapping rectangular units, Bedrock House is nestled in the Mediterranean landscape. Separating the house into distinct modules enabled the architects to maximize views from the interior. Two walls bisect the project, and a pool runs the length of the exterior, sea-facing terrace. The complex is decidedly minimalist, with white walls and a glass curtain wall arcade.\",\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Got a project the world should see? Submit it for the 9th Annual A+Awards, the largest awards program celebrating the world’s best architecture. Submit your best new projects before April 23rd, 2021 for a shot at international publication and global recognition.\",\"ranges\":[{\"element\":\"em\",\"range\":\"0,262\"},{\"element\":\"anchor\",\"range\":\"54,19\",\"url\":\"https://awards.architizer.com/architecture/awards/?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"anchor\",\"range\":\"145,29\",\"url\":\"https://www.architizerawards.com/a?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"strong\",\"range\":\"182,16\"}]},{\"node\":\"paragraph\",\"content\":\"The post These 7 Sun-Drenched Mediterranean Residences Are an Architect’s Dream appeared first on Journal.\",\"ranges\":[{\"element\":\"anchor\",\"range\":\"9,70\",\"url\":\"https://architizer.com/blog/inspiration/collections/mediterranean-residences/\"},{\"element\":\"anchor\",\"range\":\"98,7\",\"url\":\"https://architizer.com/blog\"}]}]"
