#import "Feed.h"
#import "FeedItem.h"

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>

@implementation Feed

#pragma mark -

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.authors forKey:@"authors"];
    [encoder encodeObject:self.etag forKey:@"etag"];
    [encoder encodeObject:self.favicon forKey:@"favicon"];
    [encoder encodeObject:self.feedID forKey:@"feedID"];
    [encoder encodeObject:self.folderID forKey:@"folderID"];
    [encoder encodeObject:self.articles forKey:@"articles"];
    [encoder encodeObject:self.summary forKey:@"summary"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.extra forKey:@"extra"];
    [encoder encodeObject:self.unread forKey:@"unread"];
    [encoder encodeObject:self.hub forKey:@"hub"];
    [encoder encodeBool:self.hubSubscribed forKey:@"hubSubscribed"];
    [encoder encodeBool:self.subscribed forKey:@"subscribed"];
    [encoder encodeObject:self.localName forKey:propSel(localName)];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.authors = [decoder decodeObjectOfClass:NSArray.class forKey:@"authors"];
        self.etag = [decoder decodeObjectOfClass:NSString.class forKey:@"etag"];
        self.favicon = [decoder decodeObjectOfClass:NSString.class forKey:@"favicon"];
        self.feedID = [decoder decodeObjectOfClass:NSNumber.class forKey:@"feedID"];
        self.folderID = [decoder decodeObjectOfClass:NSNumber.class forKey:@"folderID"];
        self.articles = [decoder decodeObjectOfClass:NSArray.class forKey:@"articles"];
        self.summary = [decoder decodeObjectOfClass:NSString.class forKey:@"summary"];
        self.title = [decoder decodeObjectOfClass:NSString.class forKey:@"title"];
        self.url = [decoder decodeObjectOfClass:NSString.class forKey:@"url"];
        self.extra = [decoder decodeObjectOfClass:FeedMeta.class forKey:@"extra"];
        self.unread = [decoder decodeObjectOfClass:NSNumber.class forKey:@"unread"];
        self.hub = [decoder decodeObjectOfClass:NSString.class forKey:@"hub"];
        self.hubSubscribed = [decoder decodeBoolForKey:@"hubSubscribed"];
        self.subscribed = [decoder decodeBoolForKey:@"subscribed"];
        self.localName = [decoder decodeObjectOfClass:NSString.class forKey:propSel(localName)];
    }
    return self;
}

- (instancetype)copy {
    
    Feed *instance = [Feed instanceFromDictionary:self.dictionaryRepresentation];
    
    return instance;
    
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark - Equality

- (NSUInteger)hash {
    
    NSUInteger hash = 0;
    hash += self.feedID.unsignedIntegerValue;
    
    return hash;
    
}

- (BOOL)isEqualToFeed:(Feed *)object {
    
    if (object == nil) {
        return NO;
    }
    
    if ([object isKindOfClass:Feed.class] == NO) {
        return NO;
    }
    
    return object.hash == self.hash;
}

- (BOOL)isEqual:(id)object {
    
    if (object != nil && [object isKindOfClass:Feed.class]) {
        return [self isEqualToFeed:object];
    }
    
    return NO;
    
}

+ (Feed *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Feed *instance = [[Feed alloc] init];
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
    
    if ([key isEqualToString:@"hubSubscribed"]) {
        if (!value)
            value = @(NO);
    }
    
    if ([key isEqualToString:@"unread"]) {
        if ([value isKindOfClass:NSString.class])
            value = @([value integerValue]);
        
        self.unread = value;
    }
    else if ([key isEqualToString:@"articles"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                FeedItem *populatedMember = [FeedItem instanceFromDictionary:valueMember];
                [myMembers addObject:populatedMember];
            }

            self.articles = myMembers;

        }

    }
    else if ([key isEqualToString:@"authors"]) {
        
        if ([value isKindOfClass:NSArray.class]) {
            
            NSMutableArray *members = [NSMutableArray arrayWithCapacity:[value count]];
            
            for (id valueMember in value) {
                Author *instance = [Author instanceFromDictionary:valueMember];
                
                [members addObject:instance];
            }
            
            self.authors = members.copy;
            
        }
        
    }
    else if ([key isEqualToString:@"extra"]) {
        
        if ([value isKindOfClass:FeedMeta.class] == NO && [value isKindOfClass:NSDictionary.class]) {
            FeedMeta *instance = [FeedMeta instanceFromDictionary:value];
            self.extra = instance;
        }
        
    }
    else {
        [super setValue:value forKey:key];
    }

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
    if ([key isEqualToString:@"feed"] && [value isKindOfClass:NSDictionary.class]) {
        return [self setAttributesFromDictionary:value];
    }
    else if ([key isEqualToString:@"id"]) {
        self.feedID = value;
    }
    else if ([key isEqualToString:@"status"] || [key isEqualToString:@"created"] || [key isEqualToString:@"modified"] || [key isEqualToString:@"flags"] || [key isEqualToString:@"hubLease"]) {}
    else {
        DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
    }
}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.authors) {
        
        NSMutableArray *members = [NSMutableArray arrayWithCapacity:self.authors.count];
        
        for (Author *author in self.authors) {
            [members addObject:author.dictionaryRepresentation];
        }
        
        [dictionary setObject:members.copy forKey:@"authors"];
    }

    if (self.etag) {
        [dictionary setObject:self.etag forKey:@"etag"];
    }
    
    if (self.favicon) {
        [dictionary setObject:self.favicon forKey:@"favicon"];
    }

    if (self.feedID != nil) {
        [dictionary setObject:self.feedID forKey:@"feedID"];
    }

    if (self.folder) {
        [dictionary setObject:self.folder forKey:@"folder"];
    }

    if (self.articles) {
        
        NSArray *articles = [self.articles rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        
        [dictionary setObject:articles forKey:@"articles"];
    }

    if (self.summary) {
        [dictionary setObject:self.summary forKey:@"summary"];
    }

    if (self.title) {
        [dictionary setObject:self.title forKey:@"title"];
    }

    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    if (self.extra) {
        NSDictionary *extra = [self.extra isKindOfClass:FeedMeta.class] ? [self.extra dictionaryRepresentation] : (NSDictionary *)[self extra];
        [dictionary setObject:extra forKey:@"extra"];
    }
    
    if (self.hub) {
        [dictionary setObject:self.hub forKey:@"hub"];
    }
    
    if (self.unread != nil) {
        [dictionary setObject:self.unread forKey:@"unread"];
    }
    
    if (self.folderID != nil) {
        [dictionary setObject:self.folderID forKey:@"folderID"];
    }
    
    [dictionary setObject:@(self.hubSubscribed) forKey:@"hubSubscribed"];
    [dictionary setObject:@(self.subscribed) forKey:@"subscribed"];
    
    if (self.localName) {
        [dictionary setObject:self.localName forKey:propSel(localName)];
    }

    return dictionary;

}

#pragma mark - Getters

- (NSString *)displayTitle {
    
    return self.localName ?: self.title;
    
}

- (NSString *)faviconURI {
    
    NSArray * const IMAGE_EXTENSIONS = @[@"png", @"jpg", @"jpeg", @"svg", @"bmp", @"ico", @"webp"];
    
    if (_faviconURI == nil) {
        NSString *url = nil;
        
        if (self.favicon && [self.favicon containsString:@".twimg"]) {
            url = self.favicon;
        }
        else if ([self.favicon isBlank] == NO) {
            url = self.favicon;
        }
        else if (self.extra) {
            
            if (self.extra.icons && [self.extra.icons count]) {
                
                NSMutableArray *availableKeys = [[[self.extra icons] allKeys] mutableCopy];
                
                NSInteger baseIndex = [availableKeys indexOfObject:@"base"];
                
                if (baseIndex != NSNotFound) {
                    [availableKeys removeObjectAtIndex:baseIndex];
                }
                
                availableKeys = [[availableKeys rz_map:^id(NSString *obj, NSUInteger idx, NSArray *array) {
                    return @(obj.integerValue);
                }] sortedArrayUsingSelector:@selector(compare:)].mutableCopy;
                
                url = [self.extra icons][[[availableKeys lastObject] stringValue]];
                
                if (!url && baseIndex != NSNotFound) {
                    url = [self.extra.icons valueForKey:@"base"];
                }
                
            }
            else if (self.extra.opengraph && self.extra.opengraph.image) {
                url = self.extra.opengraph.image;
            }
        }
        
        if (url != nil) {
            
            // opengraph can only contain images (samwize)
            NSString *pathExtension = url.pathExtension;
            
            // the path extension can be blank for gravatar urls
            if ([pathExtension isBlank] == NO && [IMAGE_EXTENSIONS containsObject:pathExtension] == NO) {
                url = nil;
            }
            
        }
        
        if (url == nil && self.extra.icon != nil && [self.extra.icon isBlank] == NO) {
            url = self.extra.icon;
        }
        
        if (url == nil && self.favicon != nil && [self.favicon isBlank] == NO) {
            url = self.favicon;
        }
        
        if (url == nil && self.favicon) {
            url = self.favicon;
        }
        
        if (!url || (url && [url isKindOfClass:NSString.class] && [url isBlank]))
            return url;
        
        // ensure this is not an absolute URL
        NSURLComponents *components = [NSURLComponents componentsWithString:url];
        
        if (components.host == nil) {
            // this is a relative string
            components = [NSURLComponents componentsWithString:self.extra.url ?: self.url];
            components.path = url;
            
            url = [components URL].absoluteString;
        }
        
        if (components.scheme == nil) {
            components.scheme = @"https";
            url = [components URL].absoluteString;
        }
        
        if (url != nil && [url.pathExtension isEqualToString:@"ico"]) {
            NSURLComponents *components = [NSURLComponents componentsWithString:url];
            url = formattedString(@"https://www.google.com/s2/favicons?domain=%@", components.host);
        }
        
        _faviconURI = url;
    }
    
    return _faviconURI;
}

@end
