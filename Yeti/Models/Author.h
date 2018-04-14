//
//  Author.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>

@interface Author : DZCloudObject

@property (nonatomic, copy) NSNumber *authorID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bio;

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs;

@end
