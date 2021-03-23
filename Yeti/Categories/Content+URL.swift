//
//  Content+URL.swift
//  Elytra
//
//  Created by Nikhil Nigade on 23/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Models

extension Content {
    
    public func urlCompliantWith(preference: ImageLoadingOption, width: CGFloat) -> URL? {
        
        return urlCompliantWith(preference: preference, width: width, darkModeOnly: false)
        
    }
    
    public func urlCompliantWith(preference: ImageLoadingOption, width: CGFloat, darkModeOnly: Bool = false) -> URL? {
        
        var url: URL? = url ?? attributes?.value(for: "src") as? URL
        
        var usedSRCSet: Bool = false
        
        if let srcset = srcSet,
           srcset.keys.count > 1 {
            
            var sizes = srcset.keys
            
            var canUseDark = darkModeOnly
            
            if canUseDark == false,
               let _ = srcset["dark"] {
                
                DispatchQueue.main.sync {
                    
                    let windows = UIApplication.shared.windows
                    if let key = windows.first(where: { $0.isKeyWindow }) {
                        
                        if key.traitCollection.userInterfaceStyle == .dark {
                            canUseDark = true
                        }
                        
                    }
                    
                }
                
            }
            
            var assignedDarkImage = false
            
            if canUseDark == true {
                
                if let darkSet = (srcset as? [String: [String: String]])?["dark"] {
                    
                    sizes = darkSet.keys
                    
                    print("Using dark srcset for \(String(describing: url))")
                    
                    if sizes.contains("1x") || sizes.contains("2x") {
                        
                        if preference == .lowRes,
                           let resource = darkSet["1x"] {
                            
                            url = URL(string: resource)
                            assignedDarkImage = true
                            usedSRCSet = true
                            
                        }
                        else if preference != .lowRes,
                                let resource = darkSet["2x"] {
                            
                            url = URL(string: resource)
                            assignedDarkImage = true
                            usedSRCSet = true
                            
                        }
                        
                    }
                    
                    if sizes.contains("3x"),
                       preference == .highRes,
                       let resource = darkSet["3x"] {
                        
                        url = URL(string: resource)
                        assignedDarkImage = true
                        usedSRCSet = true
                        
                    }
                    
                }
                
            }
         
            if assignedDarkImage == true {
                
                return checkAndFinalise(url, usedSRCSet: usedSRCSet, maxWidth: width)
                
            }
            
            var source: [String: String]? = srcset
            
            if canUseDark == true {
                
                if let darkSource = (srcset as? [String: [String: String]])?["dark"] {
                    source = darkSource
                }
                
            }
            
            guard source != nil else {
                return nil
            }
            
            if preference == .lowRes {
                
                // match keys a little below the width
                let available = sizes.filter {
                    let compare: Float = ($0 as NSString).floatValue
                    return compare < Float(width) && (compare - 100) <= Float(width)
                }.sorted(by: { return $0.compare($1, options: .numeric) == .orderedAscending })
                
                if available.count > 0 {
                    url = URL(string: srcset[available.last!]!)!
                    usedSRCSet = true
                }
                
            }
            else if preference == .mediumRes {
                
                // match keys a little above the width
                let available = sizes.filter {
                    let compare: Float = ($0 as NSString).floatValue
                    return compare > Float(width) && (compare + 100) <= Float(width)
                }.sorted(by: { return $0.compare($1, options: .numeric) == .orderedAscending })
                
                if available.count > 0 {
                    url = URL(string: srcset[available.last!]!)!
                    usedSRCSet = true
                }
                
            }
            else {
                
                // match keys higher than our width
                let available = sizes.filter {
                    let compare: Float = ($0 as NSString).floatValue
                    return compare > Float(width) && (compare + 200) <= Float(width)
                }.sorted(by: { return $0.compare($1, options: .numeric) == .orderedAscending })
                
                if available.count > 0 {
                    url = URL(string: srcset[available.last!]!)!
                    usedSRCSet = true
                }
                
                if url == nil,
                   let largeFile: String = attributes?["data-large-file"] {
                    
                    url = URL(string: largeFile)
                    usedSRCSet = true
                    
                }
                
            }
            
        }
        
        return checkAndFinalise(url, usedSRCSet: usedSRCSet, maxWidth: width)
        
    }
    
    func checkAndFinalise(_ inURL: URL?, usedSRCSet: Bool, maxWidth: CGFloat) -> URL? {
        
        guard let url = inURL else {
            return nil
        }
        
        var retval: URL? = URL(string: url.absoluteString)
        
        if url.host == nil {
            
            // relative path.
            // check if main url has host.
            if self.url != nil,
               let host = self.url?.host {
                
                retval = URL(string: "\(host)\(url)")
                
            }
            
        }
        
        guard var path = retval?.absoluteString else {
            return nil
        }
        
        path = path.path(forImageProxy: false, maxWidth: maxWidth, quality: 0.9)
        
        return URL(string: path)
        
    }
    
}
