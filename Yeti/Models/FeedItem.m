#import "FeedItem.h"

#import "Content.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSDate+ISO8601.h>

#import "NSString+HTML.h"
#import <DZKit/NSString+Extras.h>
#import <CoreServices/CoreServices.h>

@implementation FeedItem

static NSDateFormatter *_formatter = nil;

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    
    [encoder encodeObject:self.articleTitle forKey:@"articleTitle"];
    [encoder encodeObject:self.articleURL forKey:@"articleURL"];
    [encoder encodeObject:self.author forKey:@"author"];
    [encoder encodeObject:self.blogTitle forKey:@"blogTitle"];
    [encoder encodeObject:self.content forKey:@"content"];
    [encoder encodeObject:self.coverImage forKey:@"coverImage"];
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.modified forKey:@"modified"];
    [encoder encodeObject:self.timestamp forKey:@"timestamp"];
    
    [encoder encodeObject:@(self.bookmarked) forKey:@"bookmarked"];
    [encoder encodeObject:@(self.read) forKey:@"read"];
    
    [encoder encodeObject:self.mediaCredit forKey:@"mediaCredit"];
    [encoder encodeObject:self.mediaDescription forKey:@"mediaDescription"];
    [encoder encodeObject:self.mediaRating forKey:@"mediaRating"];
    [encoder encodeObject:self.itunesImage forKey:@"itunesImage"];
    
    [encoder encodeObject:self.enclosures forKey:@"enclosures"];
    
    [encoder encodeObject:self.feedID forKey:@"feedID"];
    [encoder encodeObject:self.summary forKey:@"summary"];
    
    [encoder encodeBool:self.mercury forKey:propSel(mercury)];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        self.identifier = [decoder decodeObjectOfClass:[NSNumber class] forKey:@"identifier"];
        self.articleTitle = [decoder decodeObjectOfClass:[NSString class] forKey:@"articleTitle"];
        self.articleURL = [decoder decodeObjectOfClass:[NSString class] forKey:@"articleURL"];
        self.author = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSDictionary.class, NSString.class, nil] forKey:@"author"];
        self.blogTitle = [decoder decodeObjectOfClass:[NSString class] forKey:@"blogTitle"];
        
        self.bookmarked = [([decoder decodeObjectOfClass:[NSNumber class] forKey:@"bookmarked"] ?: @0) boolValue];
        self.read = [([decoder decodeObjectOfClass:NSNumber.class forKey:@"read"]  ?: @1) boolValue];
        
        self.content = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, Content.class, nil] forKey:@"content"];
        self.coverImage = [decoder decodeObjectOfClass:[NSString class] forKey:@"coverImage"];
        self.guid = [decoder decodeObjectOfClass:[NSString class] forKey:@"guid"];
        self.modified = [decoder decodeObjectOfClass:[NSString class] forKey:@"modified"];
        self.timestamp = [decoder decodeObjectOfClass:[NSDate class] forKey:@"timestamp"];
        
        self.mediaCredit = [decoder decodeObjectOfClass:[NSString class] forKey:@"mediaCredit"];
        self.mediaDescription = [decoder decodeObjectOfClass:[NSString class] forKey:@"mediaDescription"];
        self.mediaRating = [decoder decodeObjectOfClass:[NSString class] forKey:@"mediaRating"];
        self.itunesImage = [decoder decodeObjectOfClass:[NSString class] forKey:@"itunesImage"];
        
        self.enclosures = [decoder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, Enclosure.class, nil] forKey:@"enclosures"];
        
        self.feedID = [decoder decodeObjectOfClass:[NSNumber class] forKey:@"feedID"];
        self.summary = [decoder decodeObjectOfClass:[NSString class] forKey:@"summary"];
        self.mercury = [decoder decodeBoolForKey:@"mercury"];
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
                NSLog(@"Exception when setting summary: %@", exc);
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
    else if ([key isEqualToString:@"mediaRating"] || [key isEqualToString:@"mediaDescription"] || [key isEqualToString:@"modified"]) {} else if ([key isEqualToString:@"keywords"]) {}
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
        NSLog(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
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
        
        NSString *strDate = (NSString *)[self modified];
        
        if ([self.modified isKindOfClass:NSDate.class]) {
            strDate = [[self.class formatter] stringFromDate:(NSDate *)strDate];
        }
        
        [dictionary setObject:strDate forKey:@"modified"];
        
    }

    [dictionary setObject:[NSNumber numberWithBool:self.read] forKey:@"read"];

    if (self.timestamp) {
        
        NSString *strDate = (NSString *)[self timestamp];
        
        if ([self.timestamp isKindOfClass:NSDate.class]) {
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

#pragma mark -

- (NSString *)textFromContent {
    
    if (self.content == nil) {
        return nil;
    }
    
    if (_textFromContent == nil) {
        
        NSMutableString *str = [NSMutableString new];
        
        for (Content *content in self.content) {
            
            NSString *inner = [self textFromContent:content];
            
            [str appendFormat:@" %@", inner];
            
        }
        
        _textFromContent = [str stringByStrippingWhitespace];
        
    }
    
    return _textFromContent;
    
}

- (NSString *)textFromContent:(Content *)content {
    
    NSMutableString *str = [NSMutableString new];
    
    if (content.content) {
        [str appendFormat:@" %@", content.content];
    }
    else if (content.items && content.items.count) {
        
        for (Content *innerC in content.items) {
            
            NSString *inner = [self textFromContent:innerC];
            
            [str appendFormat:@" %@", inner];
            
        }
        
    }
    
    return str.copy;
    
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

- (NSUInteger)hash {
    
    NSUInteger hash = self.compareID.hash;
    
    hash += self.feedID.hash;
//    hash += self.isRead ? 1 : 0;
//    hash += self.isBookmarked ? 1 : 0;
//    hash += self.mercury ? 1 : 0;
    
    return hash;
    
}

- (BOOL)isEqualToItem:(FeedItem *)item {
    
    if (item != nil && item.hash == self.hash) {
        return YES;
    }
    
    return (item != nil
            && [item.identifier isEqualToNumber:self.identifier]
            && [item.feedID isEqualToNumber:self.feedID]
            && (item.content ? item.content.hash == self.content.hash : YES)
            && item.mercury == self.mercury);
    
}

- (BOOL)isEqual:(id)object {
    
    if (object == nil) {
        return NO;
    }
    
    if ([object isKindOfClass:FeedItem.class] == NO) {
        return NO;
    }
    
    if ([(FeedItem *)object identifier].integerValue == self.identifier.integerValue) {
        
        return [self isEqualToItem:object];
        
    }
    else {
        return NO;
    }
    
    
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

- (NSItemProvider *)itemProvider {
    
    NSString *articleURL = self.articleURL;
    
    return [[NSItemProvider alloc] initWithObject:articleURL];
    
}

@end
