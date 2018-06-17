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

#import <SimpleKeychain/SimpleKeychain.h>

NSString *const kAccountID = @"YTUserID";
NSString *const kUserID = @"userID";
NSNotificationName const YTUserNotFound = @"com.yeti.note.userNotFound";

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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // get changes that might have happened while this
            // instance of our app wasn't running
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            if (store) {
                @synchronized (store) {
                    [store synchronize];
                }
            }
        });
    });
}

- (instancetype)initWithDelegate:(id<YTUserDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
        A0SimpleKeychain *keychain = self.delegate.keychain;
        
        NSString *UUIDString = [keychain stringForKey:kAccountID];
        
        _userID = @([[keychain stringForKey:kUserID] integerValue]);
        
        if (_userID && _userID.integerValue == 0) {
            _userID = nil;
            _UUID = nil;
            UUIDString = nil;
        }
        
        // migrate from NSUbiquitousKeyValueStore
        if (!UUIDString || !self.userID) {
            NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
            UUIDString = [defaults stringForKey:kAccountID];
            
            if (UUIDString) {
                self.UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
            }
            
            NSInteger userID = [defaults longLongForKey:kUserID];
            if (userID) {
                self.userID = @(userID);
            }
        }
        
        // migrate from NSUserDefaults
        if (!UUIDString || !self.userID) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            UUIDString = [defaults stringForKey:kAccountID];
            
            if (UUIDString) {
                self.UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
            }
            
            NSInteger userID = [[defaults valueForKey:kUserID] integerValue];
            if (userID) {
                self.userID = @(userID);
            }
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
            });
            
            // check server
            if (self.delegate) {
                
                weakify(self);
                
                [self.delegate getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
                    NSDictionary *user = [responseObject valueForKey:@"user"];
                    DDLogDebug(@"Got existing user: %@", user);
                    
                    self->_userID = @([[user valueForKey:@"id"] integerValue]);
                    self->_UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
                    
                    [keychain setString:self->_userID.stringValue forKey:kUserID];
                    [keychain setString:self->_UUID.UUIDString forKey:kAccountID];
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
                    self->_UUID = [NSUUID UUID];
                    [keychain setString:self->_UUID.UUIDString forKey:kAccountID];
                    
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
        [self.delegate.keychain setString:UUID.UUIDString forKey:kAccountID];
    }
}

- (NSString *)UUIDString {
    return self.UUID.UUIDString;
}

- (void)setUserID:(NSNumber *)userID
{
    _userID = userID;
    
    if (_userID != nil) {
        [self.delegate.keychain setString:userID.stringValue forKey:kUserID];
    }
    
    MyFeedsManager.userID = _userID;
}

@end
