#import "Folder.h"
#import "Feed.h"

@implementation Folder

- (NSString *)compareID {
    return [self.folderID stringValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.created forKey:@"created"];
    [encoder encodeObject:self.feeds forKey:@"feeds"];
    [encoder encodeObject:self.folderID forKey:@"folderID"];
    [encoder encodeObject:self.modified forKey:@"modified"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.userID forKey:@"userID"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.created = [decoder decodeObjectForKey:@"created"];
        self.feeds = [decoder decodeObjectForKey:@"feeds"];
        self.folderID = [decoder decodeObjectForKey:@"folderID"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
        self.status = [decoder decodeObjectForKey:@"status"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.userID = [decoder decodeObjectForKey:@"userID"];
    }
    return self;
}

- (BOOL)isEqualToFolder:(Folder *)object {
    return ([[object folderID] isEqualToNumber:self.folderID]
            && [[object title] isEqualToString:self.title]);
}

- (BOOL)isEqual:(id)object {
    
    if ([object isKindOfClass:Folder.class]) {
        return [self isEqualToFolder:object];
    }
    
    return NO;
    
}

- (instancetype)copy {
    Folder *instance = [Folder instanceFromDictionary:self.dictionaryRepresentation];
    
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self copy];
}

+ (Folder *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Folder *instance = [[Folder alloc] init];
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

//- (void)setValue:(id)value forKey:(NSString *)key
//{
//
//    if ([key isEqualToString:@"feeds"]) {
//
//        if ([value isKindOfClass:[NSPointerArray class]])
//        {
//            self.feeds = value;
//        }
//
//    } else {
//        
//    }
//
//}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{

    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"folderID"];
    } else {
//        [super setValue:value forUndefinedKey:key];
    }

}

#pragma mark -

- (NSNumber *)unreadCount {
    
    NSInteger count = 0;
    
    for (Feed *feed in self.feeds) {
        count += [feed.unread integerValue];
    }
    
    return @(count);
    
}

#pragma mark -

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.created) {
        [dictionary setObject:self.created forKey:@"created"];
    }

    if (self.feeds) {
        
        NSMutableArray *feedMembers = [NSMutableArray arrayWithCapacity:self.feeds.count];
        
        for (Feed *feed in self.feeds) {
            if (feed) {
                if (feed.folderID == nil) {
                    feed.folderID = self.folderID;
                }
                
                NSDictionary *dict = [feed dictionaryRepresentation];
                [feedMembers addObject:dict];
            }
        }
        
        [dictionary setObject:feedMembers forKey:@"feeds"];
        
    }

    if (self.folderID != nil) {
        [dictionary setObject:self.folderID forKey:@"folderID"];
    }

    if (self.modified) {
        [dictionary setObject:self.modified forKey:@"modified"];
    }

    if (self.status != nil) {
        [dictionary setObject:self.status forKey:@"status"];
    }

    if (self.title) {
        [dictionary setObject:self.title forKey:@"title"];
    }

    if (self.userID != nil) {
        [dictionary setObject:self.userID forKey:@"userID"];
    }

    return dictionary;

}


@end
