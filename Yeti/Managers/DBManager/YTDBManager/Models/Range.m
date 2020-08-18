#import "Range.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>

@implementation Range

+ (BOOL)supportsSecureCoding {
    return YES;
}

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
        self.element = [decoder decodeObjectOfClass:[NSString class] forKey:@"element"];
        self.range = NSRangeFromString([decoder decodeObjectOfClass:[NSString class] forKey:@"range"]);
        self.type = [decoder decodeObjectOfClass:[NSString class] forKey:@"type"];
        self.url = [decoder decodeObjectOfClass:[NSString class] forKey:@"url"];
        self.level = [decoder decodeObjectOfClass:[NSString class] forKey:@"level"];
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
    
    if ([value isKindOfClass:NSDate.class]) {
        
    }
    
    if ([key isEqualToString:@"range"] && [value isKindOfClass:NSString.class]) {
        value = [NSValue valueWithRange:NSRangeFromString(value)];
    }
    
    if ([key isEqualToString:@"url"] && value && [value isKindOfClass:NSArray.class]) {
        value = [(NSArray *)value rz_reduce:^id(id prev, id current, NSUInteger idx, NSArray *array) {
            if ([current isKindOfClass:NSString.class] && [(NSString *)current isBlank] == NO) {
                return current;
            }
            
            return prev;
        }];
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"href"]) {
        self.url = value;
    }
    else
        NSLog(@"Warning: %@ : %@-%@", NSStringFromClass(self.class), key, value);
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
