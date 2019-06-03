#import "FeedItem.h"

#import "Content.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSDate+ISO8601.h>

#import "NSString+HTML.h"
#import <DZKit/NSString+Extras.h>

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

@implementation FeedItem

static NSDateFormatter *_formatter = nil;

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    
    [encoder encodeObject:self.articleTitle forKey:@"articleTitle"];
    [encoder encodeObject:self.articleURL forKey:@"articleURL"];
    [encoder encodeObject:self.author forKey:@"author"];
    [encoder encodeObject:self.blogTitle forKey:@"blogTitle"];
    [encoder encodeObject:[NSNumber numberWithBool:self.bookmarked] forKey:@"bookmarked"];
    [encoder encodeObject:self.content forKey:@"content"];
    [encoder encodeObject:self.coverImage forKey:@"coverImage"];
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.modified forKey:@"modified"];
    [encoder encodeObject:[NSNumber numberWithBool:self.read] forKey:@"read"];
    [encoder encodeObject:self.timestamp forKey:@"timestamp"];
    
    [encoder encodeObject:self.mediaCredit forKey:@"mediaCredit"];
    [encoder encodeObject:self.mediaDescription forKey:@"mediaDescription"];
    [encoder encodeObject:self.mediaRating forKey:@"mediaRating"];
    [encoder encodeObject:self.itunesImage forKey:@"itunesImage"];
    
    [encoder encodeObject:self.keywords forKey:propSel(keywords)];
    [encoder encodeObject:self.enclosures forKey:@"enclosures"];
    
    [encoder encodeObject:self.feedID forKey:@"feedID"];
    [encoder encodeObject:self.summary forKey:@"summary"];
    
    [encoder encodeBool:self.mercury forKey:propSel(mercury)];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.articleTitle = [decoder decodeObjectForKey:@"articleTitle"];
        self.articleURL = [decoder decodeObjectForKey:@"articleURL"];
        self.author = [decoder decodeObjectForKey:@"author"];
        self.blogTitle = [decoder decodeObjectForKey:@"blogTitle"];
        self.bookmarked = [(NSNumber *)[decoder decodeObjectForKey:@"bookmarked"] boolValue];
        self.content = [decoder decodeObjectForKey:@"content"];
        self.coverImage = [decoder decodeObjectForKey:@"coverImage"];
        self.guid = [decoder decodeObjectForKey:@"guid"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
        self.read = [(NSNumber *)[decoder decodeObjectForKey:@"read"] boolValue];
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        
        self.mediaCredit = [decoder decodeObjectForKey:@"mediaCredit"];
        self.mediaDescription = [decoder decodeObjectForKey:@"mediaDescription"];
        self.mediaRating = [decoder decodeObjectForKey:@"mediaRating"];
        self.itunesImage = [decoder decodeObjectForKey:@"itunesImage"];
        
        self.keywords = [decoder decodeObjectForKey:@"keywords"];
        self.enclosures = [decoder decodeObjectForKey:@"enclosures"];
        
        self.feedID = [decoder decodeObjectForKey:@"feedID"];
        self.summary = [decoder decodeObjectForKey:@"summary"];
        self.mercury = [decoder decodeObjectForKey:propSel(mercury)];
    }
    return self;
}

+ (FeedItem *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    FeedItem *instance = [[FeedItem alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;

}

- (instancetype)copyWithZone:(NSZone *)zone
{
    FeedItem *copy = [[FeedItem alloc] init];
    [copy setAttributesFromDictionary:self.dictionaryRepresentation];
    
    return copy;
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

    if ([key isEqualToString:@"content"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                Content *populatedMember = [Content instanceFromDictionary:valueMember];
                [myMembers addObject:populatedMember];
            }

            self.content = myMembers;

        }

    }
    
    else if ([key isEqualToString:@"timestamp"]) {
        if ([value isKindOfClass:NSString.class]) {
            value = [[self.class formatter] dateFromString:value];
        }
        
        self.timestamp = value;
    }
    
    else if ([key isEqualToString:@"keywords"]) {
        
        if ([value isKindOfClass:NSString.class]) {
            self.keywords = [[(NSString *)value componentsSeparatedByString:@","] rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                return obj && [obj isBlank] == NO;
            }];
        }
        else if ([value isKindOfClass:NSArray.class]) {
            self.keywords = value;
        }
        
        if (self.keywords != nil && self.keywords.count) {
            // remove Uncategorized from the list
            self.keywords = [self.keywords rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                NSString *lower = [obj lowercaseString];
                return ([lower isEqualToString:@"uncategorized"] || [lower isEqualToString:@"uncategorised"]) == NO;
            }];
        }
        
    }
    
    else if ([key isEqualToString:@"enclosures"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                Enclosure *populatedMember = [Enclosure instanceFromDictionary:valueMember];
                [myMembers addObject:populatedMember];
            }

            self.enclosures = myMembers;

        }

    }
    else if ([key isEqualToString:@"summary"]) {
        if (value && ![value isBlank]) {
            @try {
                self.summary = [value htmlToPlainText];
            }
            @catch (NSException *exc) {
                DDLogWarn(@"Exception when setting summary: %@", exc);
            }
        }
    }
    else if ([key isEqualToString:@"bookmarked"]) {
        [super setValue:value forKey:key];
    }
    else {
       [super setValue:value forKey:key];
    }

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifier = value;
    }
    else if ([key isEqualToString:@"mediaRating"] || [key isEqualToString:@"mediaDescription"] || [key isEqualToString:@"modified"]) {}
    else if ([key isEqualToString:@"url"]) {
        self.articleURL = value;
    }
    else if ([key isEqualToString:@"created"]) {
        if ([value isKindOfClass:NSString.class]) {
            value = [(NSString *)value stringByReplacingOccurrencesOfString:@".000Z" withString:@"Z"];
            value = [NSDate ISO8601DateFromString:(NSString *)value];
        }
        
        self.timestamp = value;
    }
    else if ([key isEqualToString:@"title"]) {
        self.articleTitle = value;
    }
    else {
        DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
    }
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.identifier != nil) {
        [dictionary setObject:self.identifier forKey:@"id"];
    }

    if (self.articleTitle) {
        [dictionary setObject:self.articleTitle forKey:@"articleTitle"];
    }

    if (self.articleURL) {
        [dictionary setObject:self.articleURL forKey:@"articleURL"];
    }

    if (self.author) {
        [dictionary setObject:self.author forKey:@"author"];
    }

    if (self.blogTitle) {
        [dictionary setObject:self.blogTitle forKey:@"blogTitle"];
    }

    [dictionary setObject:[NSNumber numberWithBool:self.bookmarked] forKey:@"bookmarked"];

    if (self.content) {
        NSArray <NSDictionary *> *content = [self.content rz_map:^id(DZObject *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        [dictionary setObject:content forKey:@"content"];
    }

    if (self.coverImage) {
        [dictionary setObject:self.coverImage forKey:@"coverImage"];
    }

    if (self.guid) {
        [dictionary setObject:self.guid forKey:@"guid"];
    }

    if (self.modified) {
        [dictionary setObject:self.modified forKey:@"modified"];
    }

    [dictionary setObject:[NSNumber numberWithBool:self.read] forKey:@"read"];

    if (self.timestamp) {
        
        NSString *strDate = (NSString *)[self timestamp];
        if ([self.timestamp isMemberOfClass:NSDate.class]) {
            strDate = [[self.class formatter] stringFromDate:(NSDate *)strDate];
        }
        
        [dictionary setObject:strDate forKey:@"timestamp"];
    }
    
    if (self.itunesImage) {
        [dictionary setObject:self.itunesImage forKey:@"itunesImage"];
    }
    
    if (self.mediaCredit) {
        [dictionary setObject:self.mediaCredit forKey:@"mediaCredit"];
    }
    
    if (self.mediaDescription) {
        [dictionary setObject:self.mediaDescription forKey:@"mediaDescription"];
    }
    
    if (self.mediaRating) {
        [dictionary setObject:self.mediaRating forKey:@"mediaRating"];
    }
    
    if (self.keywords) {
        [dictionary setObject:self.keywords forKey:propSel(keywords)];
    }
    
    if (self.enclosures) {
        NSArray <NSDictionary *> *enclosures = [self.enclosures rz_map:^id(Enclosure *obj, NSUInteger idx, NSArray *array) {
            return obj.dictionaryRepresentation;
        }];
        [dictionary setObject:enclosures forKey:@"enclosures"];
    }
    
    if (self.feedID != nil) {
        [dictionary setObject:self.feedID forKey:@"feedID"];
    }
    
    if (self.summary) {
        [dictionary setObject:self.summary forKey:@"summary"];
    }
    
    [dictionary setObject:@(self.mercury) forKey:propSel(mercury)];

    return dictionary;

}

#pragma mark - Getters

- (NSString *)compareID
{
    return self.identifier.stringValue;
}

- (NSComparisonResult)compare:(FeedItem *)item
{
    return [self.identifier.stringValue compare:item.identifier.stringValue options:NSNumericSearch];
}

- (BOOL)isEqualToItem:(FeedItem *)item {
    
    return (item != nil
            && [item.identifier isEqualToNumber:self.identifier]
            && [item.feedID isEqualToNumber:self.feedID]
            && (item.content ? item.content.hash == self.content.hash : YES)
            && item.mercury == self.mercury);
    
}

- (BOOL)isEqual:(id)object {
    
    if (object != nil && [object isKindOfClass:FeedItem.class]) {
        BOOL retval = [self isEqualToItem:object];
        
        return retval;
    }
    
    return NO;
    
}

+ (NSDateFormatter *)formatter
{
    if (!_formatter) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [formatter setLocale:enUSPOSIXLocale];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        
        _formatter = formatter;
    }
    
    return _formatter;
}

+ (void)setFormatter:(NSDateFormatter *)formatter
{
    _formatter = formatter;
}

#pragma mark - Setter

- (void)setCoverImage:(NSString *)coverImage {
    if (coverImage && [coverImage isBlank]) {
        coverImage = nil;
    }
    
    _coverImage = coverImage;
}

@end
