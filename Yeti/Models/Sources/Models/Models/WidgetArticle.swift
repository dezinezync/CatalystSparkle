//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 25/03/21.
//

import Foundation

public final class WidgetArticle: Article {
 
    public var blog: String?
    public var favicon: URL?
    
    public enum CodingKeys: String, CodingKey {
        case blog, favicon
    }
    
    public required override init() {
        super.init()
    }
    
    public convenience init(copyFrom article: Article) {
        
        self.init()
        
        for caseKey in Article.CodingKeys.allCases {
            
            if let val: Codable = article.value(for: caseKey.rawValue) as? Codable {
                
                self.setValue(val, forKey: caseKey.rawValue)
                
            }
            
            identifier = article.identifier
            timestamp = article.timestamp
            fulltext = article.fulltext
            coverImage = article.coverImage
            
        }
        
    }
    
    public required init(from decoder: Decoder) throws {
        
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blog = try? container.decode(String.self, forKey: .blog)
        favicon = try? container.decode(URL.self, forKey: .favicon)
        
    }
    
    public override func encode(to encoder: Encoder) throws {
        
        try? super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(blog, forKey: .blog)
        try? container.encodeIfPresent(favicon, forKey: .favicon)
        
    }
    
}
