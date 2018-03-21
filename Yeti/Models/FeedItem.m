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

- (NSString *)compareID
{
    return self.guid;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.primedContent forKey:@"primedContent"];
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
    [encoder encodeObject:self.enclosures forKey:@"enclosures"];
    
    [encoder encodeObject:self.feedID forKey:@"feedID"];
    [encoder encodeObject:self.summary forKey:@"summary"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.primedContent = [decoder decodeObjectForKey:@"primedContent"];
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
        self.enclosures = [decoder decodeObjectForKey:@"enclosures"];
        
        self.feedID = [decoder decodeObjectForKey:@"feedID"];
        self.summary = [decoder decodeObjectForKey:@"summary"];
    }
    return self;
}

+ (FeedItem *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    FeedItem *instance = [[FeedItem alloc] init];
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
            self.summary = [value htmlToPlainText];
        }
    }
    else {
       [super setValue:value forKey:key];
    }

}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
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
    else
        DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.identifier != nil) {
        [dictionary setObject:self.identifier forKey:@"id"];
    }
    
    if (self.primedContent) {
        [dictionary setObject:self.primedContent forKey:@"primedContent"];
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
        [dictionary setObject:self.timestamp forKey:@"timestamp"];
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

    return dictionary;

}

@end
