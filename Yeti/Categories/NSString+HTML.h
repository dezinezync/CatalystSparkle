//
//  NSString+HTML.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HTML)

- (NSString *)htmlToPlainText;

- (NSString *)stringByDecodingHTMLEntities;

@end
