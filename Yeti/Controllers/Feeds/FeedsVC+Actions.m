//
//  FeedsVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Actions.h"
#import <DZKit/AlertManager.h>
#import <DZKit/DZBasicDatasource.h>
#import "FeedsManager.h"

@implementation FeedsVC (Actions)

- (void)beginRefreshing:(UIRefreshControl *)sender {
    
    if (_refreshing || _preCommitLoading || !_noPreSetup)
        return;
    
    _refreshing = YES;
    
    weakify(self);
    
    [MyFeedsManager getFeeds:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        asyncMain(^{
            strongify(self);
            
            [self setupData:MyFeedsManager.feeds];
            
            [sender endRefreshing];
        });
        
        _refreshing = NO;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"%@", error);
        
        asyncMain(^{
            [sender endRefreshing];
        });
        
        _refreshing = NO;
        
    }];
    
}

- (void)didTapAdd:(UIBarButtonItem *)add
{
    
    __block __strong UITextField *_tf = nil;
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"New Feed" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    weakify(self);
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *path = _tf.text;
        
        _tf = nil;
        
        NSURL *URL = [[NSURL alloc] initWithString:path];
        
        if (!URL) {
            [AlertManager showGenericAlertWithTitle:@"Invalid URL" message:@"The URL you provided was invalid. Please check it and try again."];
            return;
        }
        
        [MyFeedsManager addFeed:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObject:responseObject];
            
            strongify(self);
            
            DZBasicDatasource *DS = [self valueForKeyPath:@"DS"];
            DS.data = MyFeedsManager.feeds;
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"An error occurred" message:error.localizedDescription];
            
        }];
        
    }]];
    
    [avc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        _tf = textField;
        
        _tf.placeholder = @"Feed URL";
    }];
    
    asyncMain(^{
        
        strongify(self);
        
        [self presentViewController:avc animated:YES completion:nil];
        
    });
    
}

@end
