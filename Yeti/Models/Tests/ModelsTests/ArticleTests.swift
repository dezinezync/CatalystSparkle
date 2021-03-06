//
//  ArticleTests.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
import Combine
@testable import Models

final class ArticleTests: XCTestCase {
    
    static func makeArticle(jsonString: String) -> Article {
        
        guard let data = jsonString.data(using: .utf8) else {
            fatalError("Invalid data from JSON String")
        }
        
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError("No JSON object from data")
        }
        
        return Article(from: obj)
        
    }
    
    func testInitFromDict () {
        
        let article = Self.makeArticle(jsonString: articleJSON)
        
        XCTAssertEqual(article.identifier, 23560549)
        
    }
    
    func testDictRepresentation() {
        
        let article = Self.makeArticle(jsonString: articleJSON)
        let dict = article.dictionaryRepresentation
    
        for key in dict.keys {
            
            if key == "content" || key == "enclosures" || key == "read" || key == "bookmarked" || key == "fulltext" {
                continue
            }
            
            let a = dict[key] as? AnyHashable
            var b = article.value(for: key) as? AnyHashable
            
            if key == "url" || key == "coverImage" {
                b = (b as? URL)?.absoluteString
            }
            else if key == "timestamp" {
                b = Subscription.dateFormatter.string(from: b as! Date)
            }
            
            print("\(key)\n\(String(describing: a))\n\(String(describing: b))")
            
            XCTAssertEqual(a, b)
            
        }
        
    }
    
    func testTextFromContent () {
        
        let article = Self.makeArticle(jsonString: microBlogArticleJSON)
        
        let content = article.textFromContent
        
        XCTAssertEqual(content, "I earned this award by winning my February Challenge! #AppleWatch 26 complete rings out of 28 days. 2 break days. That’s quite a lot of me personally. Now I need a break and a slow March. Come on Apple Fitness Algorithms, go easy on us. 😅")
        
    }
    
    func testTextFromContentPerformance () {
        
        let article = Self.makeArticle(jsonString: articleJSON)
        
        measure {
            let _ = article.textFromContent
        }
        
    }
    
    func testDescription () {
        
        let article = Self.makeArticle(jsonString: articleJSON)
        let description = article.description
        
        XCTAssert(description.contains("Article:"))
        
    }
    
    var disposables = [AnyCancellable]()
    
    var isRead = false
    func testReadPublisher() {
        
        let article = Article()
        
        article.$read
            .removeDuplicates()
            .map { input -> Bool in
                return input!
            }
            .assign(to: \.isRead, on: self)
            .store(in: &disposables)
        
        article.read = true
        XCTAssertEqual(isRead, true)
        
    }
    
    var isBookmarked = false
    func testBookmarkedPublisher() {
        
        let article = Article()
        
        article.$bookmarked
            .removeDuplicates()
            .map { input -> Bool in
                return input!
            }
            .assign(to: \.isBookmarked, on: self)
            .store(in: &disposables)
        
        article.bookmarked = true
        XCTAssertEqual(isBookmarked, true)
        
    }
    
    var isFullText = false
    func testFulltextPublisher() {
        
        let article = Article()
        
        article.$fulltext
            .removeDuplicates()
            .map { input -> Bool in
                return input!
            }
            .assign(to: \.isFullText, on: self)
            .store(in: &disposables)
        
        article.fulltext = true
        XCTAssertEqual(isFullText, true)
        
    }

}

private let articleJSON = "{\"id\":23560549,\"title\":\"These 7 Sun-Drenched Mediterranean Residences Are an Architect’s Dream\",\"url\":\"https://architizer.com/blog/inspiration/collections/mediterranean-residences/\",\"content\":[{\"node\":\"paragraph\",\"content\":\"It’s not too late to enter the 9th Annual A+Awards, the world’s largest architectural awards program! Submit your best new projects before April 23rd, 2021 for a shot at international publication and worldwide recognition.\",\"ranges\":[{\"element\":\"em\",\"range\":\"0,222\"},{\"element\":\"anchor\",\"range\":\"31,19\",\"url\":\"https://awards.architizer.com/architecture/awards/?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"anchor\",\"range\":\"102,29\",\"url\":\"https://www.architizerawards.com/a?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"strong\",\"range\":\"139,16\"}]},{\"node\":\"paragraph\",\"content\":\"The Mediterranean has long hosted opportunities for architects to design environments of leisure, from Roman escapes on the Gulf of Baia to Adalberto Libera’s Villa Malaparte on Capri — famously featured in Jean-Luc Goddard’s 1963 film Contempt. These seven homes expand and elaborate on the heritage of the Mediterranean summer holiday.\",\"ranges\":[{\"element\":\"em\",\"range\":\"236,9\"}]},{\"node\":\"paragraph\",\"content\":\"Many utilize plaster, a traditional material in the region that reflects solar heat and helps to cool in the hot months, while others take a more subdued approach with local stone and exposed concrete. Renovations such as Amelia Tavella’s Casa Santa Teresa on the island of Corsica and Rubén Muedra Estudio de Arquitectura’s Dune House demonstrate the possibilities for adapting and preserving modernist vacation getaways for contemporary clients. The unifying theme of these striking residences is an extraordinary sea view and a spectacular coastal setting.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/1585489027959WEB-IMG_9209.jpg\",\"size\":\"2500,1667\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Pool with sea view\"}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-768x512.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-1024x683.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-1536x1024.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR-2048x1366.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/1585488989697WEB-IMG_9098-HDR.jpg\"},\"size\":\"2500,1667\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"node\":\"a\",\"content\":\"Casa Santa Teresa\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,17\"}],\"url\":\"https://architizer.com/projects/casa-santa-teresa/\"},{\"node\":\"paragraph\",\"content\":\" by AMELIA TAVELLA ARCHITECTES, Ajaccio, France\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"This home on the Corsican coast is designed around natural elements: the sea, flowering bougainvillea, the breeze, and sunlight. Thoughtful features such as pivoting doors and slatted shutters allow the residence to fully open to the climate in summer, adjusting to the light and heat of the day. A pool in the center of a stone terrace directly abuts a sandy beach stretching across the edge of the property. Exterior plaster walls and interior white paint, as well as a wooden brise soliel and interior finishings connect the distinct zones of the project.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-300x158.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-400x210.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-768x403.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-1024x538.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-1536x806.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001-2048x1075.jpg\",\"2335\":\"https://blog.architizer.com/wp-content/uploads/1579781038326Ruben_Muedra_Vivienda_en_Oliva_001.jpg\"},\"size\":\"2335,1226\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2335px)\",\"100vw,\",\"2335px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-768x512.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-1024x683.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-2048x1366.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/1579781055630Ruben_Muedra_Vivienda_en_Oliva_011-scaled.jpg\"},\"size\":\"2560,1708\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"a\",\"content\":\"Dune House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/dune-house-2/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Rubén Muedra Estudio de Arquitectura\",\"ranges\":[],\"url\":\"https://www.rubenmuedra.com/\"},{\"node\":\"paragraph\",\"content\":\", Oliva, Spain\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Crouched behind a dune on the Valencian coast, Dune House is a renovated bunker-like modernist home from the 1940s. The overall profile is squat—a white roofline pressed against the sky, but elevated just enough to offer an uninterrupted view of the Balearic Sea. From the terrace, the panoramic view is framed by a white concrete window, reflected into a swimming pool. The interior is similarly monochrome, with white kitchen cabinets and furniture. Hued sliding glass doors echo the chromatic contrast between the home and the sky.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222.jpeg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-300x200.jpeg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-400x267.jpeg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-768x512.jpeg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222-1024x683.jpeg\",\"1344\":\"https://blog.architizer.com/wp-content/uploads/1563530817743WhatsApp_Image_2018-11-28_at_18.58.222.jpeg\"},\"size\":\"1344,896\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"1344px)\",\"100vw,\",\"1344px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/1563530762118WhatsApp_Image_2018-11-28_at_18.58.15.jpeg\",\"size\":\"1344,896\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Apartment with tiled ceiling\"}},{\"node\":\"a\",\"content\":\"Romantic Nest in Amalfi Coast\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,29\"}],\"url\":\"https://architizer.com/projects/romantic-nest-in-amalfi-coast/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Ernesto Fusco Interior Design\",\"ranges\":[],\"url\":\"https://www.ernestofusco.it/?lang=en\"},{\"node\":\"paragraph\",\"content\":\", Cetara, Italy\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"A traditional product of the Amalfi Coast region is multicolored majolica tile, many produced in the seaside resort of Vietri Sul Mare at the Paolo Soleri-designed Ceramica Solimene factory. Ernesto Fusco’s renovation of a sea-view apartment in the cliffside town of Cetara showcases majolica ceramics in a unique ceiling and kitchen counter splash composed of the colorful tiles. The design is particularly suitable as the apartment’s terrace faces the signature green-and-yellow majolica dome of the local parish.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/1403254290802Int_Ibi_Brigitte_DefR05.jpg\",\"size\":\"6048,4032\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Plaster walls with terrace and pool\"}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/1403254377967Int_Ibi_Brigitte_DefR30.jpg\",\"size\":\"6048,4032\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Apartment interior with contemporary furniture\"}},{\"node\":\"a\",\"content\":\"Dupli Dos\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,9\"}],\"url\":\"https://architizer.com/projects/dupli-dos/\"},{\"node\":\"paragraph\",\"content\":\"by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"JUMA architects\",\"ranges\":[],\"url\":\"https://www.jumaarchitects.com/en\"},{\"node\":\"paragraph\",\"content\":\", Ibiza, Spain\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"JUMA Architects united two holiday apartments into one unit on the Spanish island of Ibiza. This consolidation necessitated the removal of a staircase and the creation of a single outdoor terrace. The resulting patio offers expansive views of the Balearic Sea, disturbed only by interspersed cacti. With its white walls, sea views, and terrace, the home epitomizes the classic Mediterranean holiday escape.\",\"ranges\":[]},{\"node\":\"gallery\",\"images\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-300x212.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-400x283.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-768x543.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-1024x723.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-1536x1085.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-2048x1447.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/15300200084092-1-scaled.jpg\"},\"size\":\"2560,1809\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-300x240.jpg\",\"376\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-376x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-768x613.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-1024x817.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-1536x1226.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-2048x1635.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/153002004544811-scaled.jpg\"},\"size\":\"2560,2044\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}}]},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/15300200326386.jpg\",\"size\":\"5000,3999\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Concrete portico with pool\"}},{\"node\":\"a\",\"content\":\"Ring House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/ring-house/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Deca Architecture\",\"ranges\":[],\"url\":\"http://decablogs.squarespace.com/new-page-1\"},{\"node\":\"paragraph\",\"content\":\", Agia Galini, Greece\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Ring House is built into a mountainside slope overlooking Messara Bay, with a C-shape that enables it to maintain a low topographic profile. It is composed primarily of two materials: local stone and concrete. Tension between the two creates dramatically different perceptions. Viewed from the pool, the residence is an ultra-modern getaway, whereas from the exterior incline the muted brown stone and grey concrete camouflage into the arid scrubland. To reduce the impact of construction in an ecologically sensitive zone, the architects surveyed and collected seeds from native fauna, then used to restore the landscape that was altered by construction access roads.\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-scaled.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-300x240.jpg\",\"375\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-375x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-768x614.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-1024x819.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-1536x1229.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-2048x1639.jpg\",\"2560\":\"https://blog.architizer.com/wp-content/uploads/1488193423493BONTE__MIGOZZI_VILLA_KGET_JK_EXTERIEURS_84_3JK_7878_copie-scaled.jpg\"},\"size\":\"2560,2048\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2560px)\",\"100vw,\",\"2560px\"]}},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-300x240.jpg\",\"375\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-375x300.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S-768x614.jpg\",\"900\":\"https://blog.architizer.com/wp-content/uploads/1488193378461BONTE__MIGOZZI_VILLA_KGET_JK__dARGENT_17_3JK_7906_S.jpg\"},\"size\":\"900,720\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"900px)\",\"100vw,\",\"900px\"]}},{\"node\":\"a\",\"content\":\"villa kget\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,10\"}],\"url\":\"https://architizer.com/projects/villa-kget/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"bonte et migozzi architectes\",\"ranges\":[],\"url\":\"http://bonte-migozzi.com/\"},{\"node\":\"paragraph\",\"content\":\", Ensuès-la-Redonne, France\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"On account of its narrow plot, villa kget is elevated on stilts to project over the hillside. Mimicking the elongated forms of the stilts, wooden slats encapsulate the residence’s exterior. The interior is similarly replete with wood, a xyloid theme that befits the home’s location amid a coastal Mediterranean pine forest. The tapered interior opens into covered terraces with superb views of the Gulf of Marseille.\",\"ranges\":[]},{\"node\":\"gallery\",\"images\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-768x513.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1024x684.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-2048x1367.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/154733963757604_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\"},\"size\":\"2500,1669\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"node\":\"image\",\"url\":\"https://architizer-prod.imgix.net/media/mediadata/uploads/154733940285319_Bedrock_House_-_Idis_Turato_-_Turato_Architects__SECTIONS.jpg\",\"size\":\"2500,1869\",\"attr\":{\"loading\":\"lazy\",\"alt\":\"Cross-section of home\"}}]},{\"node\":\"container\",\"content\":[{\"node\":\"image\",\"url\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\",\"srcset\":{\"300\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-300x200.jpg\",\"400\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-400x267.jpg\",\"768\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-768x513.jpg\",\"1024\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1024x684.jpg\",\"1536\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-1536x1025.jpg\",\"2048\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic-2048x1367.jpg\",\"2500\":\"https://blog.architizer.com/wp-content/uploads/154733935643213_Bedrock_House_-_Idis_Turato_-_Turato_Architects__photo_BosnicDorotic.jpg\"},\"size\":\"2500,1669\",\"attr\":{\"loading\":\"lazy\",\"sizes\":[\"(max-width:\",\"2500px)\",\"100vw,\",\"2500px\"]}},{\"node\":\"a\",\"content\":\"Bedrock House\",\"ranges\":[{\"element\":\"strong\",\"range\":\"0,13\"}],\"url\":\"https://architizer.com/projects/bedrock-house-2/\"},{\"node\":\"paragraph\",\"content\":\" by \",\"ranges\":[]},{\"node\":\"a\",\"content\":\"Turato Architects / Idis Turato\",\"ranges\":[],\"url\":\"https://idisturato.tumblr.com/\"},{\"node\":\"paragraph\",\"content\":\", Brzac, Croatia\",\"ranges\":[]}],\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Composed of two overlapping rectangular units, Bedrock House is nestled in the Mediterranean landscape. Separating the house into distinct modules enabled the architects to maximize views from the interior. Two walls bisect the project, and a pool runs the length of the exterior, sea-facing terrace. The complex is decidedly minimalist, with white walls and a glass curtain wall arcade.\",\"ranges\":[]},{\"node\":\"paragraph\",\"content\":\"Got a project the world should see? Submit it for the 9th Annual A+Awards, the largest awards program celebrating the world’s best architecture. Submit your best new projects before April 23rd, 2021 for a shot at international publication and global recognition.\",\"ranges\":[{\"element\":\"em\",\"range\":\"0,262\"},{\"element\":\"anchor\",\"range\":\"54,19\",\"url\":\"https://awards.architizer.com/architecture/awards/?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"anchor\",\"range\":\"145,29\",\"url\":\"https://www.architizerawards.com/a?utm_source=blog&utm_medium=architizer_website&utm_campaign=main-entry\"},{\"element\":\"strong\",\"range\":\"182,16\"}]},{\"node\":\"paragraph\",\"content\":\"The post These 7 Sun-Drenched Mediterranean Residences Are an Architect’s Dream appeared first on Journal.\",\"ranges\":[{\"element\":\"anchor\",\"range\":\"9,70\",\"url\":\"https://architizer.com/blog/inspiration/collections/mediterranean-residences/\"},{\"element\":\"anchor\",\"range\":\"98,7\",\"url\":\"https://architizer.com/blog\"}]}],\"author\":\"Gavin Moulton\",\"coverImage\":\"\",\"guid\":\"https://architizer.com/blog/?p=68344\",\"summary\":\"<p>These seven Mediterranean homes feature extraordinary sea views and highlight unique approaches to regional architecture.</p>\",\"itunesImage\":null,\"keywords\":\"Collections,Inspiration\",\"mediaCredit\":null,\"mediaRating\":null,\"mediaDescription\":null,\"feedID\":17003,\"mercury\":true,\"created\":\"2021-03-04T13:45:28.000Z\",\"modified\":\"2021-03-04T13:45:28.000Z\",\"read\":false,\"bookmarked\":false,\"enclosures\":[]}"

let microBlogArticleJSON = "{\"id\":23321747,\"title\":\"\",\"url\":\"https://dezinezync.com/2021/02/28/i-earned-this.html\",\"content\":[{\"node\":\"paragraph\",\"content\":\"I earned this award by winning my February Challenge! #AppleWatch 26 complete rings out of 28 days. 2 break days. That’s quite a lot of me personally.\",\"ranges\":[]},{\"node\":\"container\",\"content\":[{\"node\":\"paragraph\",\"content\":\"Now I need a break and a slow March. Come on Apple Fitness Algorithms, go easy on us. 😅\",\"ranges\":[]},{\"node\":\"image\",\"url\":\"https://dezinezync.com/uploads/2021/0590c7b1cb.jpg\",\"attr\":{\"alt\":\"9431477E-8CF2-442E-AE7B-1B3BBBC140A2.jpg\"}}],\"ranges\":[]}],\"author\":\"\",\"coverImage\":\"\",\"guid\":\"http://dezinezync.micro.blog/2021/02/28/i-earned-this.html\",\"summary\":null,\"itunesImage\":null,\"keywords\":\"\",\"mediaCredit\":null,\"mediaRating\":null,\"mediaDescription\":null,\"feedID\":11478,\"mercury\":false,\"created\":\"2021-02-28T14:24:56.000Z\",\"modified\":\"2021-02-28T14:24:56.000Z\",\"read\":1,\"bookmarked\":false,\"enclosures\":[]}"
