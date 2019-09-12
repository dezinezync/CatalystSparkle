#import "Content.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import "YetiConstants.h"

#import "NSString+ImageProxy.h"

@implementation Content

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)compareID {
    return [@(self.hash) stringValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.content forKey:@"content"];
    [encoder encodeObject:self.ranges forKey:@"ranges"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.alt forKey:@"alt"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.level forKey:@"level"];
    [encoder encodeObject:self.items forKey:@"items"];
    [encoder encodeObject:self.attributes forKey:@"attributes"];
    [encoder encodeObject:self.videoID forKey:@"videoID"];
    [encoder encodeCGSize:self.size forKey:@"size"];
    [encoder encodeObject:self.srcset forKey:@"srcset"];
    [encoder encodeObject:self.images forKey:@"images"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.content = [decoder decodeObjectOfClass:[NSString class] forKey:@"content"];
        self.ranges = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, Range.class, nil] forKey:@"ranges"];
        self.type = [decoder decodeObjectOfClass:[NSString class] forKey:@"type"];
        self.identifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
        self.alt = [decoder decodeObjectOfClass:[NSString class] forKey:@"alt"];
        self.url = [decoder decodeObjectOfClass:[NSString class] forKey:@"url"];
        self.items = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, Content.class, nil] forKey:@"items"];
        self.level = [decoder decodeObjectOfClass:[NSNumber class] forKey:@"level"];
        self.attributes = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, NSDictionary.class, nil] forKey:@"attributes"];
        self.videoID = [decoder decodeObjectOfClass:[NSString class] forKey:@"videoID"];
        self.size = [decoder decodeCGSizeForKey:@"size"];
        self.srcset = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@"srcset"];
        self.images = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, Content.class, nil] forKey:@"images"];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Content *instance = [Content new];
    
    [instance setValuesForKeysWithDictionary:self.dictionaryRepresentation];
    
    return instance;
}

+ (Content *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Content *instance = [[Content alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;

}

- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary
{

    if (![aDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }

    [self setValuesForKeysWithDictionary:aDictionary];

}

- (void)setValue:(id)value forKey:(NSString *)key
{
    
    if ([value isKindOfClass:NSDate.class]) {
        
    }
    
    if ([key isEqualToString:@"content"] && value && [value isKindOfClass:NSArray.class])
        key = @"items";

    if ([key isEqualToString:@"ranges"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                if ([valueMember isKindOfClass:NSDictionary.class])
                    [myMembers addObject:[Range instanceFromDictionary:valueMember]];
                else
                    [myMembers addObject:valueMember];
            }

            self.ranges = myMembers;

        }

    }
    else if ([key isEqualToString:@"items"] && [value isKindOfClass:NSArray.class]) {
        
        NSArray <Content *> *items = [value rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [Content instanceFromDictionary:obj];
        }];
        
        [super setValue:items forKey:key];
        
    }
    else if ([key isEqualToString:@"images"] && [value isKindOfClass:NSArray.class]) {
        
        NSArray <Content *> *items = [value rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [Content instanceFromDictionary:obj];
        }];
        
        [super setValue:items forKey:key];
        
    }
    else if ([key isEqualToString:@"size"] && [value isKindOfClass:NSString.class]) {
        NSArray *components = [value componentsSeparatedByString:@","];
        if (components.count > 1) {
            CGSize size = CGSizeMake([components[0] floatValue], [components[1] floatValue]);
            self.size = size;
        }
    }
    else {
        
        if ([key isEqualToString:@"type"]) {
            if ([value isEqualToString:@"img"])
                value = @"image";
            else if ([value isEqualToString:@"p"])
                value = @"paragraph";
            else if ([value isEqualToString:@"ul"])
                value = @"unorderedList";
            else if ([value isEqualToString:@"ol"])
                value = @"orderedList";
            else if ([value isEqualToString:@"header"]) {
                value = @"heading";
            }
            else if ([[value substringToIndex:1] isEqualToString:@"h"] && [(NSString *)value length] == 2 && ![value isEqualToString:@"hr"]) {
                self.level = @([[value substringFromIndex:1] integerValue]);
                value = @"heading";
            }
        }
        
        [super setValue:value forKey:key];
    }

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"construct"] && [value isKindOfClass:NSArray.class]) {
        NSArray *arr = (NSArray *)value;
        if (arr.count) {
            NSArray <Content *> *items = [arr rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [Content instanceFromDictionary:obj];
            }];
            
            if (self.items && self.items.count)
                self.items = [self.items arrayByAddingObjectsFromArray:items];
            else
                self.items = items;
        }
    }
    else if ([key isEqualToString:@"node"]) {
        [self setValue:value forKey:@"type"];
    }
    else if ([key isEqualToString:@"text"]) {
        [self setValue:value forKey:@"content"];
    }
    else if ([key isEqualToString:@"src"]) {
        [self setValue:value forKey:@"url"];
    }
    else if ([key isEqualToString:@"attr"]) {
        [self setValue:value forKey:@"attributes"];
    }
    else if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"identifier"];
    }
    else if ([key isEqualToString:@"media"]) {
        [self setValue:value forKey:@"images"];
    }
    else
        DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.content) {
        [dictionary setObject:self.content forKey:@"content"];
    }

    if (self.ranges) {
        
        NSArray <NSDictionary *> *ranges = [self.ranges rz_map:^id(Range *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        
        [dictionary setObject:ranges forKey:@"ranges"];
    }

    if (self.type) {
        [dictionary setObject:self.type forKey:@"type"];
    }
    
    if (self.alt) {
        [dictionary setObject:self.alt forKey:@"alt"];
    }
    
    if (self.identifier) {
        [dictionary setObject:self.identifier forKey:@"identifier"];
    }
    
    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    if (self.level != nil) {
        [dictionary setObject:self.level forKey:@"level"];
    }
    
    if (self.items) {
        
        NSArray <NSDictionary *> *items = [self.items rz_map:^id(Content *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        
        [dictionary setObject:items forKey:@"items"];
    }
    
    if (self.attributes) {
        [dictionary setObject:self.attributes forKey:@"attributes"];
    }
    
    if (self.videoID) {
        [dictionary setObject:self.videoID forKey:@"videoID"];
    }
    
    if (self.size.width && self.size.height) {
        [dictionary setObject:NSStringFromCGSize(self.size) forKey:@"size"];
    }
    
    if (self.srcset) {
        [dictionary setObject:self.srcset forKey:@"srcset"];
    }
    
    if (self.images) {
        
        NSArray <NSDictionary *> *mapped = [self.images rz_map:^id(Content *obj, NSUInteger idx, NSArray *array) {
            return [obj dictionaryRepresentation];
        }];
        
        [dictionary setObject:mapped forKey:@"images"];
        
    }

    return dictionary;

}

#pragma mark -

#ifndef SHARE_EXTENSION

- (NSString *)urlCompliantWithUsersPreferenceForWidth:(CGFloat)width
{
    NSString *url = (self.url ?: [self.attributes valueForKey:@"src"]);
    
    BOOL usedSRCSet = NO;
    
    NSString *sizePreference = SharedPrefs.imageLoading;
    
    if (self.srcset && [self.srcset allKeys].count > 1) {
        NSArray <NSString *> * sizes = [self.srcset allKeys];
        
        if ([sizePreference isEqualToString:ImageLoadingLowRes]) {
            // match keys a little below the width
            NSArray <NSString *> *available = [[sizes rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                CGFloat compare = obj.floatValue;
                return (compare < width && (compare - 100.f) <= width);
            }] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSNumericSearch];
            }];
            
            if (available.count) {
                url = [self.srcset valueForKey:available.lastObject];
                usedSRCSet = YES;
            }
        }
        else if ([sizePreference isEqualToString:ImageLoadingMediumRes]) {
            // match keys a little above the width
            NSArray <NSString *> *available = [[sizes rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                CGFloat compare = obj.floatValue;
                return (compare > width && (compare - 100.f) <= width);
            }] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSNumericSearch];
            }];
            
            if (available.count) {
                url = [self.srcset valueForKey:available.lastObject];
                usedSRCSet = YES;
            }
        }
        else {
            // match keys much higher than our width
            NSArray <NSString *> *available = [[sizes rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                CGFloat compare = obj.floatValue;
                return (compare > width && (compare + 200.f) >= width);
            }] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSNumericSearch];
            }];
            
            if (available.count) {
                url = [self.srcset valueForKey:available.lastObject];
                usedSRCSet = YES;
            }
            else if ([self.attributes valueForKey:@"data-large-file"]) {
                url = [self.attributes valueForKey:@"data-large-file"];
                usedSRCSet = YES;
            }
        }
    }
    
    url = [url pathForImageProxy:usedSRCSet maxWidth:0.f quality:0.f];
    
    return url;
}

#endif

@end
