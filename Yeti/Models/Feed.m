#import "Feed.h"
#import "FeedItem.h"

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>

@implementation Feed

- (NSString *)faviconURI
{
    NSString *url = nil;
    
    if (self.favicon && ![self.favicon isBlank]) {
        url = self.favicon;
    }
    else if (self.extra) {
        
        if ([self.extra valueForKey:@"appleTouch"] && [self.extra[@"appleTouch"] count]) {
            // get the base image
            url = [self.extra[@"appleTouch"] valueForKey:@"base"];
        }
        else if ([self.extra valueForKey:@"apple-touch-icon"] && [self.extra[@"apple-touch-icon"] count]) {
            // get the base image
            url = [self.extra[@"apple-touch-icon"] valueForKey:@"152"] ?: [self.extra[@"apple-touch-icon"] valueForKey:@"base"];
        }
        else if ([self.extra valueForKey:@"opengraph"] && [self.extra[@"opengraph"] valueForKey:@"image:secure_url"]) {
            url = [self.extra[@"opengraph"] valueForKey:@"image:secure_url"];
        }
        else if ([self.extra valueForKey:@"opengraph"] && [self.extra[@"opengraph"] valueForKey:@"image"]) {
            url = [self.extra[@"opengraph"] valueForKey:@"image"];
        }
        
    }
    
    return url;
}

#pragma mark -

- (NSString *)compareID
{
    return [self.feedID stringValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.authors forKey:@"authors"];
    [encoder encodeObject:self.etag forKey:@"etag"];
    [encoder encodeObject:self.favicon forKey:@"favicon"];
    [encoder encodeObject:self.feedID forKey:@"feedID"];
    [encoder encodeObject:self.folder forKey:@"folder"];
    [encoder encodeObject:self.articles forKey:@"articles"];
    [encoder encodeObject:self.summary forKey:@"summary"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.extra forKey:@"extra"];
    [encoder encodeObject:self.unread forKey:@"unread"];
    [encoder encodeObject:self.hub forKey:@"hub"];
    [encoder encodeBool:self.hubSubscribed forKey:@"hubSubscribed"];
    [encoder encodeBool:self.subscribed forKey:@"subscribed"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.authors = [decoder decodeObjectForKey:@"authors"];
        self.etag = [decoder decodeObjectForKey:@"etag"];
        self.favicon = [decoder decodeObjectForKey:@"favicon"];
        self.feedID = [decoder decodeObjectForKey:@"feedID"];
        self.folder = [decoder decodeObjectForKey:@"folder"];
        self.articles = [decoder decodeObjectForKey:@"articles"];
        self.summary = [decoder decodeObjectForKey:@"summary"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.extra = [decoder decodeObjectForKey:@"extra"];
        self.unread = [decoder decodeObjectForKey:@"unread"];
        self.hub = [decoder decodeObjectForKey:@"hub"];
        self.hubSubscribed = [decoder decodeBoolForKey:@"hubSubscribed"];
        self.subscribed = [decoder decodeBoolForKey:@"subscribed"];
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
    else if ([key isEqualToString:@"status"] || [key isEqualToString:@"created"] || [key isEqualToString:@"modified"] || [key isEqualToString:@"flags"]) {}
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
        [dictionary setObject:self.extra forKey:@"extra"];
    }
    
    if (self.hub) {
        [dictionary setObject:self.hub forKey:@"hub"];
    }
    
    [dictionary setObject:@(self.hubSubscribed) forKey:@"hubSubscribed"];
    [dictionary setObject:@(self.subscribed) forKey:@"subscribed"];

    return dictionary;

}


@end
