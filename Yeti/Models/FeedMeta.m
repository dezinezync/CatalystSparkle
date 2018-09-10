#import "FeedMeta.h"

@implementation FeedMeta
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.icons forKey:@"icons"];
    [encoder encodeObject:self.precomposed forKey:@"precomposed"];
    [encoder encodeObject:self.descriptionText forKey:@"descriptionText"];
    [encoder encodeObject:self.feedlinks forKey:@"feedlinks"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeObject:self.keywords forKey:@"keywords"];
    [encoder encodeObject:self.opengraph forKey:@"opengraph"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.icons = [decoder decodeObjectForKey:@"icons"];
        self.precomposed = [decoder decodeObjectForKey:@"precomposed"];
        self.descriptionText = [decoder decodeObjectForKey:@"descriptionText"];
        self.feedlinks = [decoder decodeObjectForKey:@"feedlinks"];
        self.icon = [decoder decodeObjectForKey:@"icon"];
        self.keywords = [decoder decodeObjectForKey:@"keywords"];
        self.opengraph = [decoder decodeObjectForKey:@"opengraph"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.url = [decoder decodeObjectForKey:@"url"];
    }
    return self;
}

+ (FeedMeta *)instanceFromDictionary:(NSDictionary *)aDictionary
{

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

    if ([key isEqualToString:@"apple-touch-icon"] || [key isEqualToString:@"appleTouch"]) {

        if ([value isKindOfClass:[NSDictionary class]]) {
            self.icons = value;
        }

    } else if ([key isEqualToString:@"feedlinks"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                [myMembers addObject:valueMember];
            }

            self.feedlinks = myMembers;

        }

    } else if ([key isEqualToString:@"keywords"]) {

        if ([value isKindOfClass:[NSArray class]])
        {

            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                [myMembers addObject:valueMember];
            }

            self.keywords = myMembers;

        }

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
    } else if ([key isEqualToString:@"apple-touch-icon-precomposed"]) {
        [self setValue:value forKey:@"precomposed"];
    } else if ([key isEqualToString:@"description"]) {
        [self setValue:value forKey:@"descriptionText"];
    } else {
//        [super setValue:value forUndefinedKey:key];
    }

}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.icons) {
        [dictionary setObject:self.icons forKey:@"icons"];
    }

    if (self.precomposed) {
        [dictionary setObject:self.precomposed forKey:@"precomposed"];
    }

    if (self.descriptionText) {
        [dictionary setObject:self.descriptionText forKey:@"descriptionText"];
    }

    if (self.feedlinks) {
        [dictionary setObject:self.feedlinks forKey:@"feedlinks"];
    }

    if (self.icon) {
        [dictionary setObject:self.icon forKey:@"icon"];
    }

    if (self.keywords) {
        [dictionary setObject:self.keywords forKey:@"keywords"];
    }

    if (self.opengraph) {
        [dictionary setObject:self.opengraph forKey:@"opengraph"];
    }

    if (self.title) {
        [dictionary setObject:self.title forKey:@"title"];
    }

    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }

    return dictionary;

}


@end
