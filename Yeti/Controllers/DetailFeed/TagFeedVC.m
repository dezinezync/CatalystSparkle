//
//  TagFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "TagFeedVC.h"
#import "FeedsManager.h"

@interface TagFeedVC ()

@end

@implementation TagFeedVC

- (instancetype)initWithTag:(NSString *)tag {
    
    if (self = [super initWithNibName:NSStringFromClass(DetailFeedVC.class) bundle:nil]) {
        self.tag = tag;
        _canLoadNext = YES;
        self.page = 0;
        
        self.customFeed = FeedTypeTag;
        
        self.sizeCache = @[].mutableCopy;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.tag;
    
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available for %@", self.tag);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)setupHeaderView { }

- (void)reloadHeaderView { }

- (void)setupLayout {
    
    self->_shouldShowHeader = NO;
    
    [super setupLayout];
    
}

- (void)loadNextPage
{
    
    if (self.DS.state != DZDatasourceLoaded)
        return;
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    self.DS.state = DZDatasourceLoading;
    
    NSInteger page = self.page + 1;
    
    [MyFeedsManager getTagFeed:self.tag page:page success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!self)
            return;
        
        NSArray *articles = responseObject[@"articles"];
        NSArray *feeds = responseObject[@"feeds"];
        
        self.page = page;
        
        if (![responseObject count]) {
            self->_canLoadNext = NO;
            self.DS.data = self.DS.data ?: @[];
        }
        
        if (page == 1 || self.DS.data == nil) {
            self.DS.data = articles;
            MyFeedsManager.temporaryFeeds = feeds;
            
            if (self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self loadNextPage];
            }
        }
        else {
            self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:articles];
            
            MyFeedsManager.temporaryFeeds = [MyFeedsManager.temporaryFeeds arrayByAddingObjectsFromArray:feeds];
        }
        
        self.DS.state = DZDatasourceLoaded;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        self.DS.state = DZDatasourceError;
        
        if (self.DS.data == nil || [self.DS.data count] == 0) {
            // the initial load has failed.
            self.DS.data = @[];
        }
        
    }];
}

#pragma mark - State Restoration

#define kBTagData @"TagData"
#define kBTagObj @"TagObject"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    NSString *tag = [coder decodeObjectForKey:kBTagObj];
    
    TagFeedVC *vc;
    
    if (tag != nil) {
        vc = [[TagFeedVC alloc] initWithTag:tag];
        vc.customFeed = FeedTypeTag;
    }
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.DS.data forKey:kBTagData];
    [coder encodeObject:self.tag forKey:kBTagObj];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray <FeedItem *> *items = [coder decodeObjectForKey:kBTagData];
    
    if (items) {
        [self setupLayout];
        
        self.DS.data = items;
    }
    
}

@end
