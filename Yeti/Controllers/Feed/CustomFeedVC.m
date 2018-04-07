//
//  CustomFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "CustomFeedVC.h"
#import "FeedsManager.h"

#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

@interface CustomFeedVC ()

@end

@implementation CustomFeedVC

#pragma mark - <ScrollLoading>

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        _canLoadNext = YES;
        _page = 1;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    self.DS.data = [MyFeedsManager unread];
}

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    if (self.isUnread) {
        _page++;
        [MyFeedsManager getUnreadForPage:_page success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (!self)
                return;
            
            if (![(NSArray *)[responseObject objectForKey:@"articles"] count]) {
                self->_canLoadNext = NO;
            }
            
            NSArray <FeedItem *> *items = [responseObject objectForKey:@"articles"];
            items = [items rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
            }];
            
            self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:items];
            
            self.loadingNext = NO;
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            DDLogError(@"%@", error);
            
            strongify(self);
            self->_page--;
            
            self.loadingNext = NO;
        }];
    }
    else {
//        [MyFeedsManager getUnreadForPage:(_page++) success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//            strongify(self);
//            
//            if (!responseObject.count) {
//                self->_canLoadNext = NO;
//            }
//            
//            asyncMain(^{
//                self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
//            });
//            
//            self->_page++;
//            self.loadingNext = NO;
//            
//        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//            DDLogError(@"%@", error);
//            
//            strongify(self);
//            
//            self.loadingNext = NO;
//        }];
    }
}

@end
