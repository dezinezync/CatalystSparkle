//
//  Author.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>

#import "Content.h"

@interface Author : DZCloudObject <NSCoding, NSCopying>

@property (nonatomic, copy) NSNumber *authorID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) Content *bio;

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs;

@end
