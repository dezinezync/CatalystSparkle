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
    public var blogID: UInt?
    
    public enum CodingKeys: String, CodingKey {
        case blog, favicon, blogID
    }
    
    public required override init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blog = try? container.decode(String.self, forKey: .blog)
        favicon = try? container.decode(URL.self, forKey: .favicon)
        blogID = try? container.decode(UInt.self, forKey: .blogID)
        
    }
    
    public override func encode(to encoder: Encoder) throws {
        
        try? super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(blog, forKey: .blog)
        try? container.encodeIfPresent(favicon, forKey: .favicon)
        try? container.encodeIfPresent(blogID, forKey: .blogID)
        
    }
    
}
