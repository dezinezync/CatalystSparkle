#import "FeedMeta.h"

@implementation FeedMeta

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.icons forKey:@"icons"];
//    [encoder encodeObject:self.descriptionText forKey:@"descriptionText"];
//    [encoder encodeObject:self.feedlinks forKey:@"feedlinks"];
//    [encoder encodeObject:self.feeds forKey:@"feeds"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeObject:self.keywords forKey:@"keywords"];
    [encoder encodeObject:self.opengraph forKey:@"opengraph"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.summary forKey:@"summary"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.icons = [decoder decodeObjectOfClass:NSDictionary.class forKey:propSel(icons)];
//        self.descriptionText = [decoder decodeObjectForKey:@"descriptionText"];
//        self.feedlinks = [decoder decodeObjectForKey:@"feedlinks"];
//        self.feeds = [decoder decodeObjectForKey:@"feeds"];
        self.icon = [decoder decodeObjectOfClass:NSString.class forKey:@"icon"];
        self.keywords = [decoder decodeObjectOfClass:NSArray.class forKey:@"keywords"];
        self.opengraph = [decoder decodeObjectOfClass:MetaOpenGraph.class forKey:@"opengraph"];
        self.title = [decoder decodeObjectOfClass:NSString.class forKey:@"title"];
        self.url = [decoder decodeObjectOfClass:NSURL.class forKey:@"url"];
        self.summary = [decoder decodeObjectOfClass:NSString.class forKey:@"summary"];
    }
    return self;
}

+ (FeedMeta *)instanceFromDictionary:(NSDictionary *)aDictionary {

    FeedMeta *instance = [[FeedMeta alloc] init];
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

    if ([key isEqualToString:@"apple-touch-icon"]) {

        if ([value isKindOfClass:[NSDictionary class]]) {
            self.icons = value;
        }

//    } else if ([key isEqualToString:@"feeds"]) {
//
//        if ([value isKindOfClass:[NSArray class]])
//        {
//
//            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
//            for (id valueMember in value) {
//                NSDictionary *populatedMember = valueMember;
//                [myMembers addObject:populatedMember];
//            }
//
//            self.feeds = myMembers;
//
//        }

    } else if ([key isEqualToString:@"opengraph"]) {

        if ([value isKindOfClass:[NSDictionary class]]) {
            self.opengraph = [MetaOpenGraph instanceFromDictionary:value];
        }

    } else {
        [super setValue:value forKey:key];
    }
    
}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{

    if ([key isEqualToString:@"apple-touch-icon"]) {
        [self setValue:value forKey:@"icons"];
    } else if ([key isEqualToString:@"description"]) {
        [self setValue:value forKey:@"descriptionText"];
    } else {
//        [super setValue:value forUndefinedKey:key];
    }

}


- (NSDictionary *)dictionaryRepresentation {

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.icons) {
        [dictionary setObject:self.icons forKey:@"icons"];
    }

//    if (self.descriptionText) {
//        [dictionary setObject:self.descriptionText forKey:@"descriptionText"];
//    }

//    if (self.feedlinks) {
//        [dictionary setObject:self.feedlinks forKey:@"feedlinks"];
//    }

//    if (self.feeds) {
//        [dictionary setObject:self.feeds forKey:@"feeds"];
//    }

    if (self.icon) {
        [dictionary setObject:self.icon forKey:@"icon"];
    }

    if (self.keywords) {
        [dictionary setObject:self.keywords forKey:@"keywords"];
    }

    if (self.opengraph) {
        NSDictionary *dict = self.opengraph ? [self.opengraph dictionaryRepresentation] : @{};
        [dictionary setObject:dict forKey:@"opengraph"];
    }

    if (self.title) {
        [dictionary setObject:self.title forKey:@"title"];
    }

    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    if (self.summary) {
        [dictionary setObject:self.summary forKey:@"summary"];
    }

    return dictionary;

}


@end
