#import "Folder.h"
#import "Feed.h"

@implementation Folder

+ (BOOL)supportsSecureCoding {
    return YES;
}

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
    [encoder encodeObject:self.feedIDs.allObjects forKey:@"feedIDs"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.created = [decoder decodeObjectOfClass:NSString.class forKey:@"created"];
        self.feeds = [decoder decodeObjectOfClass:NSPointerArray.class forKey:@"feeds"];
        self.folderID = [decoder decodeObjectOfClass:NSNumber.class forKey:@"folderID"];
        self.modified = [decoder decodeObjectOfClass:NSString.class forKey:@"modified"];
        self.status = [decoder decodeObjectOfClass:NSNumber.class forKey:@"status"];
        self.title = [decoder decodeObjectOfClass:NSString.class forKey:@"title"];
        self.userID = [decoder decodeObjectOfClass:NSNumber.class forKey:@"userID"];
        
        NSArray <NSNumber *> *feedIDs = [decoder decodeObjectOfClass:NSArray.class forKey:@"feedIDs"];
        
        if (feedIDs != nil) {
            self.feedIDs = [NSSet setWithArray:feedIDs];
        }
        
    }
    return self;
}

- (NSUInteger)hash {
    
    NSUInteger hash = 50000;
    hash += self.folderID.unsignedIntegerValue;
    
    for (NSNumber *feedID in self.feedIDs) {
        hash += feedID.unsignedIntegerValue;
    }
    
    return hash;
    
}

- (BOOL)isEqualToFolder:(Folder *)object {
    
    if (object == nil) {
        return NO;
    }
    
    if ([object isKindOfClass:Folder.class] == NO) {
        return NO;
    }
    
    BOOL checkOne = object.hash == self.hash;
    
//    BOOL checkTwo = object.isExpanded == self.isExpanded;
    
    return checkOne;
}

- (BOOL)isEqual:(id)object {
    
    if (object != nil && [object isKindOfClass:Folder.class]) {
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

- (void)setValue:(id)value forKey:(NSString *)key
{

    if ([key isEqualToString:propSel(feedIDs)]) {

        if ([value isKindOfClass:[NSArray class]])
        {
            value = [NSSet setWithArray:value];
        }
        
        self.feedIDs = value;

    }
    else if ([key isEqualToString:propSel(feeds)]
             && [value isKindOfClass:NSArray.class]
             && [(NSArray *)value count] > 0
             && [[(NSArray *)value firstObject] isKindOfClass:NSNumber.class]) {
        
        value = [NSSet setWithArray:value];
        
        self.feedIDs = value;
        
    }
    else {
        [super setValue:value forKey:key];
    }

}

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
        count += [feed.unread unsignedIntegerValue];
    }
    
    return @(count);
    
}

- (void)updateUnreadCount {
    
    if (NSThread.isMainThread == NO) {
        
        [self performSelectorOnMainThread:@selector(updateUnreadCount) withObject:nil waitUntilDone:YES];
        return;
        
    }
    
    if (self.unreadCountObservor != nil) {
        
        [self.unreadCountObservor unreadCountChangedFor:self to:self.unreadCount];
        
    }
    
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
    
    if (self.feedIDs) {
        [dictionary setObject:self.feedIDs.allObjects forKey:propSel(feedIDs)];
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
