//
//  HTMLUtils.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTMLUtils;

extern HTMLUtils *MyHTMLUtils;

@interface HTMLUtils : NSObject

- (NSString *)decode:(NSString *)entity;

@end
