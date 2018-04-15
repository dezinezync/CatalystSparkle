//
//  AuthorVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AuthorVC.h"
#import "FeedsManager.h"
#import "AuthorHeaderView.h"

@interface AuthorVC ()

@property (nonatomic, weak) AuthorHeaderView *headerView;

@end

@implementation AuthorVC

- (void)setupHeaderView {
    [self ef_hideNavBorder:self.navigationController.transitionCoordinator];
    
    if (_headerView)
        return;
    
    AuthorHeaderView *headerView = [[AuthorHeaderView alloc] initWithNib];
    headerView.author = self.author;
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.f);
    
    self.tableView.tableHeaderView = headerView;
    
    _headerView = headerView;
}

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    _page++;
    [MyFeedsManager articlesByAuthor:self.author.authorID feedID:self.feed.feedID page:_page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        if (![responseObject count]) {
            self->_canLoadNext = NO;
        }
        
        self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
        
        self.loadingNext = NO;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        self->_page--;
        
        self.loadingNext = NO;
    }];
}

@end
