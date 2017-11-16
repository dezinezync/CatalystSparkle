//
//  Enclosure.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/10/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZObject.h>


@interface Enclosure : DZObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *length;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSValue *cmtime;

+ (Enclosure *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
