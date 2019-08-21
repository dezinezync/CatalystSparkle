#import "MetaOpenGraph.h"

@implementation MetaOpenGraph

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
//    [encoder encodeObject:self.descriptionText forKey:@"descriptionText"];
    [encoder encodeObject:self.image forKey:@"image"];
    [encoder encodeObject:self.locale forKey:@"locale"];
//    [encoder encodeObject:self.title forKey:@"title"];
//    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
//        self.descriptionText = [decoder decodeObjectForKey:@"descriptionText"];
        self.image = [decoder decodeObjectForKey:@"image"];
        self.locale = [decoder decodeObjectForKey:@"locale"];
//        self.title = [decoder decodeObjectForKey:@"title"];
//        self.type = [decoder decodeObjectForKey:@"type"];
        self.url = [decoder decodeObjectForKey:@"url"];
    }
    return self;
}

+ (MetaOpenGraph *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    MetaOpenGraph *instance = [[MetaOpenGraph alloc] init];
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

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{

    if ([key isEqualToString:@"description"]) {
        [self setValue:value forKey:@"descriptionText"];
    } else {
//        [super setValue:value forUndefinedKey:key];
    }

}


- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

//    if (self.descriptionText) {
//        [dictionary setObject:self.descriptionText forKey:@"descriptionText"];
//    }

    if (self.image) {
        [dictionary setObject:self.image forKey:@"image"];
    }

    if (self.locale) {
        [dictionary setObject:self.locale forKey:@"locale"];
    }

//    if (self.title) {
//        [dictionary setObject:self.title forKey:@"title"];
//    }

//    if (self.type) {
//        [dictionary setObject:self.type forKey:@"type"];
//    }

    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }

    return dictionary;

}


@end
