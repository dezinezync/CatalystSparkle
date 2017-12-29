//
//  YTUserID.m
//  Yeti
//
//  Created by Nikhil Nigade on 26/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "YTUserID.h"
#import <DZKit/AlertManager.h>

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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            DDLogDebug(@"Initialised with: %@ %@", self.UUID, self.userID);
        });
    }
    
    return self;
}

#pragma mark -

- (NSUUID *)UUID
{
    if (!_UUID) {
        // check if the store already has one
        NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
        NSString *UUIDString = [store valueForKey:@"YTUserID"];
        
        _userID = [store valueForKey:@"userID"];
        
        if (UUIDString) {
            // we have one.
            _UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
        }
        else {
            
            // check server
            if (self.delegate) {
                weakify(self);
                
                [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    NSDictionary *user = [responseObject valueForKey:@"user"];
                    DDLogDebug(@"Got existing user: %@", user);
                    
                    _userID = @([[user valueForKey:@"id"] integerValue]);
                    _UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
                    
                    [store setValue:_userID forKey:@"userID"];
                    [store setValue:_UUID.UUIDString forKey:@"YTUserID"];
                    [store synchronize];
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    _UUID = [NSUUID UUID];
                    [store setValue:_UUID.UUIDString forKey:@"YTUserID"];
                    [store synchronize];
                    
                    strongify(self);
                    
                    // let our server know about these changes
                    [self.delegate updateUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        DDLogDebug(@"created new user");
                        NSDictionary *user = [responseObject valueForKey:@"user"];
                        self.userID = @([[user valueForKey:@"id"] integerValue]);
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        [AlertManager showGenericAlertWithTitle:@"Error loading user" message:error.localizedDescription];
                    }];
                    
                }];
            }
            
        }
        
    }
    
    return _UUID;
}

- (NSString *)UUIDString {
    return self.UUID.UUIDString;
}

- (void)setUserID:(NSNumber *)userID
{
    _userID = userID;
    
    if (_userID) {
        NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
        [store setObject:_userID forKey:@"userID"];
        [store synchronize];
    }
}

@end
