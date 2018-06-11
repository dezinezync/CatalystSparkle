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
#import "UIViewController+Hairline.h"

@interface AuthorVC ()

@property (nonatomic, weak) AuthorHeaderView *headerView;

@end

@implementation AuthorVC

- (void)setupHeaderView {
    [self ef_hideNavBorder:self.navigationController.transitionCoordinator];
    
    if (_headerView)
        return;
    
    UIImageView *imageView = [self yt_findHairlineImageViewUnder:self.navigationController.navigationBar];
    
    AuthorHeaderView *headerView = [[AuthorHeaderView alloc] initWithNib];
    headerView.author = self.author;
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.f);
    
    [headerView setShadowImage:imageView];
    
    imageView.hidden = YES;
    
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
        
        if (self->_page == 1 && self.DS.data.count) {
            self.DS.data = @[];
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
