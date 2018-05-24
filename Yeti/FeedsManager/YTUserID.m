//
//  YTUserID.m
//  Yeti
//
//  Created by Nikhil Nigade on 26/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "YTUserID.h"
#import "FeedsManager.h"
#import <DZKit/AlertManager.h>

@interface YTUserID () {
    // how many attempts have we made since waiting.
    // max is 2. Starts with 0.
    // If we reach 2, create a new user.
    NSInteger _tries;
}

@end

@implementation YTUserID

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // get changes that might have happened while this
        // instance of our app wasn't running
        [NSUbiquitousKeyValueStore.defaultStore synchronize];
    });
}

- (instancetype)initWithDelegate:(id<YTUserDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            DDLogInfo(@"Initialised with: %@ %@", self.UUID, self.userID);
        });
    }
    
    return self;
}

#pragma mark -

- (NSUUID *)UUID
{
    
    if (!_UUID) {
        // check if the store already has one
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSString *UUIDString = [store stringForKey:@"YTUserID"];
        
        self.userID = @([store longLongForKey:@"userID"]);
        
        if (!UUIDString || (_userID == nil || ![_userID integerValue])) {
            if (_tries < 2) {
                _tries++;
                return [self performSelector:@selector(UUID)];
            }
        }
        
        if (_userID && _userID.integerValue == 0) {
            _userID = nil;
            _UUID = nil;
            UUIDString = nil;
        }
        
        if (UUIDString) {
            // we have one.
            _UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
            
            if (_userID == nil || _userID.integerValue == 0) {
                // build 21 (alpha) broke this. This is a patch for that.
                if (self.delegate) {

                    [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        NSDictionary *user = [responseObject valueForKey:@"user"];
                        self.userID = @([[user valueForKey:@"id"] integerValue]);
                        
                        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        [AlertManager showGenericAlertWithTitle:@"Error loading user" message:error.localizedDescription];
                    }];
                    
                }
                
            }
            else {
                [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            }
            
        }
        else {
            
            // check server
            if (self.delegate) {
                
                weakify(self);
                
                [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
                    NSDictionary *user = [responseObject valueForKey:@"user"];
                    DDLogDebug(@"Got existing user: %@", user);
                    
                    self->_userID = @([[user valueForKey:@"id"] integerValue]);
                    self->_UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
                    
                    [store setLongLong:self->_userID.longLongValue forKey:@"userID"];
                    [store setString:self->_UUID.UUIDString forKey:@"YTUserID"];
                    [store synchronize];
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
                    self->_UUID = [NSUUID UUID];
                    [store setString:self->_UUID.UUIDString forKey:@"YTUserID"];
                    [store synchronize];
                    
                    // let our server know about these changes
                    [self.delegate updateUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        DDLogDebug(@"created new user");
                        NSDictionary *user = [responseObject valueForKey:@"user"];
                        self.userID = @([[user valueForKey:@"id"] integerValue]);
                        
                        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        [AlertManager showGenericAlertWithTitle:@"Error loading user" message:error.localizedDescription];
                    }];
                    
                }];
            }
            
        }
        
    }
    
    return _UUID;
}

- (void)setUUID:(NSUUID *)UUID
{
    _UUID = UUID;
    
    if (_UUID != nil) {
        NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
        [store setObject:[_UUID UUIDString] forKey:@"YTUserID"];
        [store synchronize];
    }
}

- (NSString *)UUIDString {
    return self.UUID.UUIDString;
}

- (void)setUserID:(NSNumber *)userID
{
    _userID = userID;
    
    if (_userID != nil) {
        NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
        [store setObject:_userID forKey:@"userID"];
        [store synchronize];
    }
    
    MyFeedsManager.userID = _userID;
}

@end
