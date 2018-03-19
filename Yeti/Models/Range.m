#import "Range.h"

@implementation Range

- (NSString *)compareID
{
    return [@(self.hash) stringValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.element forKey:@"element"];
    [encoder encodeObject:NSStringFromRange(self.range) forKey:@"range"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.level forKey:@"level"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.element = [decoder decodeObjectForKey:@"element"];
        self.range = NSRangeFromString([decoder decodeObjectForKey:@"range"]);
        self.type = [decoder decodeObjectForKey:@"type"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.level = [decoder decodeObjectForKey:@"level"];
    }
    return self;
}

+ (Range *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Range *instance = [[Range alloc] init];
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
    if ([key isEqualToString:@"range"] && [value isKindOfClass:NSString.class]) {
        value = [NSValue valueWithRange:NSRangeFromString(value)];
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"href"]) {
        self.url = value;
    }
    else
        DDLogWarn(@"%@ : %@-%@", NSStringFromClass(self.class), key, value);
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.element) {
        [dictionary setObject:self.element forKey:@"element"];
    }

    [dictionary setObject:NSStringFromRange(self.range) forKey:@"range"];

    if (self.type) {
        [dictionary setObject:self.type forKey:@"type"];
    }

    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    if (self.level != nil) {
        [dictionary setObject:self.level forKey:@"level"];
    }

    return dictionary;

}


@end
