//
//  Author.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZObject.h>

#import <DZTextKit/Content.h>

@interface Author : DZObject <NSSecureCoding, NSCopying>

@property (nonatomic, copy) NSNumber *authorID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) Content *bio;

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs;

@end
