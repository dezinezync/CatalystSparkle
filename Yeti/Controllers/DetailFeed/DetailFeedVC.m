//
//  DetailFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"

#import "ArticleCellB.h"
#import "PaddedLabel.h"
#import "DetailFeedHeaderView.h"

#import "ArticleVC.h"
#import "DetailAuthorVC.h"
#import "TagFeedVC.h"

#import "FeedsManager.h"

#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/NSArray+Safe.h>

#import "ArticleProvider.h"

#import "YetiThemeKit.h"
#import "PopMenuViewController.h"
#import "PrefsManager.h"

#import <DZKit/NSArray+RZArrayCandy.h>

NSString *const ArticlesSection = @"main";

@interface UICollectionViewController ()

- (UICollectionView *)_newCollectionViewWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout;

@end

static void *KVO_DetailFeedFrame = &KVO_DetailFeedFrame;

@interface DetailFeedVC () <DZDatasource, ArticleProvider, FeedHeaderViewDelegate, UIViewControllerRestoration, UICollectionViewDataSourcePrefetching, ArticleCellDelegate, UIAdaptivePresentationControllerDelegate> {
    UIImageView *_barImageView;
    BOOL _ignoreLoadScroll;
    
    BOOL _initialSetup;
    ArticleCellB *_protoCell;
}

@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, weak) FeedHeaderView *headerView;

@property (nonatomic, strong) NSMutableDictionary *prefetchedImageTasks;

@end

@implementation DetailFeedVC

+ (UINavigationController *)instanceWithFeed:(Feed *)feed {
    
    DetailFeedVC *instance = [[DetailFeedVC alloc] initWithFeed:feed];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"DetailFeedNavVC";
    
    return nav;
    
}

- (instancetype)initWithFeed:(Feed *)feed {
    
    if (self = [super initWithNibName:NSStringFromClass(DetailFeedVC.class) bundle:nil]) {
        self.feed = feed;
        _canLoadNext = YES;
        _page = 0;
        
        self.sizeCache = @[].mutableCopy;
        self.prefetchedImageTasks = @{}.mutableCopy;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
    }
    
    return self;
    
}

- (UICollectionView *)_newCollectionViewWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    
    if (layout == nil) {
        layout = [[UICollectionViewFlowLayout alloc] init];
    }
    
    UICollectionView *collectionView = [super _newCollectionViewWithFrame:frame collectionViewLayout:layout];
    
    return collectionView;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.feed displayTitle];
    
    self.flowLayout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    if (@available(iOS 13, *)) {
        
        weakify(self);
        
        self.DDS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, FeedItem * _Nonnull item) {
            
            strongify(self);
        
            return [self collectionView:self.collectionView cellForItemAtIndexPath:indexPath item:item];
            
        }];
        
        self.DDS.supplementaryViewProvider = ^UICollectionReusableView * _Nullable(UICollectionView * _Nonnull collectionView, NSString * _Nonnull type, NSIndexPath * _Nonnull indexPath) {
            
            strongify(self);
          
            return [self collectionView:collectionView viewForSupplementaryElementOfKind:type atIndexPath:indexPath];
            
        };
        
        NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
        [snapshot appendSectionsWithIdentifiers:@[ArticlesSection]];
        
        [self.DDS applySnapshot:snapshot animatingDifferences:NO];
        
    }
    else {
        self.DS = [[DZBasicDatasource alloc] initWithView:self.collectionView];
        self.DS.delegate = self;
        self.DS.data = @[];
        
        self.DS.addAnimation = UITableViewRowAnimationNone;
        self.DS.deleteAnimation = UITableViewRowAnimationFade;
        self.DS.reloadAnimation = UITableViewRowAnimationNone;
    }
    
    self.collectionView.prefetchDataSource = self;
    
    [self.collectionView addObserver:self forKeyPath:propSel(frame) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:KVO_DetailFeedFrame];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCellB.class) bundle:nil] forCellWithReuseIdentifier:kiPadArticleCell];
    [self.collectionView registerClass:DetailFeedHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailFeedHeaderView];
    
    // Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(author)] || (self.feed.authors && self.feed.authors.count > 1)) {
        self->_shouldShowHeader = YES;
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(didChangeContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didChangeTheme) name:kDidUpdateTheme object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    if (@available(iOS 13, *)) {
        NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
        [self.DDS applySnapshot:snapshot animatingDifferences:YES];
    }
    else {
        self.DS.data = @[];
    }
    
    _page = 0;
    _canLoadNext = YES;
    
    if (self.feed) {
        self.feed.articles = @[];
    }
    
    [AlertManager showGenericAlertWithTitle:@"Memory Warning" message:@"The app received a memory warning and to prevent unexpected crashes, it had to clear articles from the current feed. Please reload the feed to continue viewing."];
}

- (void)dealloc {
    if (self.feed) {
        self.feed.articles = @[];
    }
    
    @try {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter removeObserver:self];
        
        if (self && self.collectionView && self.collectionView.observationInfo != nil) {
            [self.collectionView removeObserver:self forKeyPath:propSel(frame) context:KVO_DetailFeedFrame];
        }
    }
    @catch (NSException *exc) {
        
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self->_initialSetup == NO) {
        [self setupNavigationBar];
        
        self->_initialSetup = YES;
        
        [self setupLayout];
        [self didChangeTheme];
    }
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectCells:self.collectionView];
    
    if (@available(iOS 13, *)) {
        if (self.DDS.snapshot.numberOfItems == 0) {
            self.controllerState = StateLoaded;
            [self loadNextPage];
        }
    }
    else {
        if (self.DS.data == nil || self.DS.data.count == 0) {
            self.DS.state = DZDatasourceLoaded;
            [self loadNextPage];
        }
    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception when unregistering: %@", exc);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (coordinator != nil) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
            [self didChangeContentCategory];
            
        } completion:nil];
    }
    else {
        [self didChangeContentCategory];
    }
    
}

- (void)_setToolbarHidden {
    self.navigationController.toolbarHidden = YES;
}

#pragma mark - Getters

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
    
}

- (NSUInteger)indexOfItem:(FeedItem *)item retIndexPath:(NSIndexPath *)outIndexPath {
    
    NSUInteger index = NSNotFound;
    
    if (item != nil && [item isKindOfClass:FeedItem.class]) {
        if (@available(iOS 13, *)) {
            NSIndexPath *indexPath = [self.DDS indexPathForItemIdentifier:item];
            
            if (indexPath != nil) {
                index = indexPath.item;
                
                outIndexPath = indexPath;
            }
            
        }
        else {
            index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:item];
        }
    }
    
    return index;
    
}

- (FeedItem *)itemForIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == nil) {
        return nil;
    }
    
    FeedItem *article = nil;
    
    if (@available(iOS 13, *)) {
        article = [self.DDS itemIdentifierForIndexPath:indexPath];
    }
    else {
        article = [self.DS objectAtIndexPath:indexPath];
    }
    
    return article;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        Theme *theme = [YTThemeKit theme];
        
        UIActivityIndicatorViewStyle style = theme.isDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [view sizeToFit];
        
        [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
        
        view.hidesWhenStopped = YES;
        
        _activityIndicatorView = view;
    }
    
    return _activityIndicatorView;
}

- (void)setRestorationIdentifier:(NSString *)restorationIdentifier {
    [super setRestorationIdentifier:restorationIdentifier];
    
    self.restorationClass = self.class;
    
    self.collectionView.restorationIdentifier = [restorationIdentifier stringByAppendingString:@"-collectionView"];
}

#pragma mark - Setters

- (void)setLoadOnReady:(NSNumber *)loadOnReady
{
    if (loadOnReady == nil) {
        _loadOnReady = loadOnReady;
        return;
    }
    
    if (@available(iOS 13, *)) {
        
        if (self.DDS == nil || self.DDS.snapshot.numberOfItems == 0) {
            weakify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                [self setLoadOnReady:loadOnReady];
            });
            
            return;
        }
        
    }
    else {
        if (self.DS == nil || self.DS.data == nil || self.DS.data.count == 0) {
            weakify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                [self setLoadOnReady:loadOnReady];
            });
            
            return;
        }
    }
    
    _loadOnReady = loadOnReady;
    
    if (loadOnReady && [[self navigationController] visibleViewController] == self) {
        // we are visible
        [self loadArticle];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (StateType)controllerState {
    return self->_controllerState;
}

- (void)setControllerState:(StateType)controllerState {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setControllerState:) withObject:@(controllerState) waitUntilDone:NO];
        return;
    }
    
    if(_controllerState != controllerState)
    {
        
        @synchronized (self) {
            self->_controllerState = controllerState;
        }
        
        if (self.DDS.snapshot == nil || self.DDS.snapshot.numberOfItems == 0) {
            // we can be in any state
            // but we should only show the empty view
            // when there is no data
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addEmptyView];
            });
        }
        else {
            // we have data, so the state doesn't matter
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeEmptyView];
            });
        }
        
    }
    
}

- (void)addEmptyView
{
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(addEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if(![self respondsToSelector:@selector(viewForEmptyDataset)])
        return;
    
    UIView *view = [self viewForEmptyDataset];
    
    if(view != nil) {
        view.tag = emptyViewTag;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        //        Check if the previous view, if existing, is present
        [self removeEmptyView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UILayoutGuide *guide = [self.view layoutMarginsGuide];
            
            [self.view addSubview:view];
            
            // this can be nil
            if (guide != nil) {
                if ([view isKindOfClass:UIActivityIndicatorView.class] == NO) {
                    [view.widthAnchor constraintEqualToAnchor:guide.widthAnchor].active = YES;
                }
                
                [view.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor].active = YES;
                [view.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor].active = YES;
            }
        });
        
    }
    
}

- (void)removeEmptyView {
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(removeEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    UIView *buffer = [self.view viewWithTag:emptyViewTag];
    
    while (buffer != nil && buffer.superview) {
        [buffer removeFromSuperview];
        
        buffer = [self.view viewWithTag:emptyViewTag];
    }
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available from %@", self.feed.title);
}

- (UIView *)viewForEmptyDataset {
    
    // since the Datasource is asking for this view
    // it will be presenting it.
    BOOL dataCheck = NO;
    
    if (@available(iOS 13, *)) {
        dataCheck = self.controllerState == StateLoading && _page == 0;
    }
    else {
        dataCheck = self.DS.state == DZDatasourceLoading && _page == 0;
    }
    
    if (dataCheck) {
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
        
        return self.activityIndicatorView;
    }
    
    if (@available(iOS 13, *)) {
        if (self.controllerState == StateDefault) {
            return nil;
        }
        
        if (self.DDS.snapshot.numberOfItems > 0) {
            return nil;
        }
    }
    else {
        if (self.DS.state == DZDatasourceDefault) {
            return nil;
        }
        
        if (self.DS.data.count > 0) {
            return nil;
        }
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGRect layoutFrame = [self.view.readableContentGuide layoutFrame];
    
    PaddedLabel *label = [[PaddedLabel alloc] init];
    label.padding = UIEdgeInsetsMake(0, layoutFrame.origin.x, 0, layoutFrame.origin.x);
    label.numberOfLines = 0;
    label.backgroundColor = theme.cellColor;
    label.opaque = YES;
    
    NSString *title = @"No Articles";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    NSDictionary *attributes = @{NSFontAttributeName: [TypeFactory shared].bodyFont,
                                 NSForegroundColorAttributeName: theme.subtitleColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [TypeFactory.shared boldBodyFont],
                   NSForegroundColorAttributeName: theme.titleColor,
                   NSParagraphStyleAttributeName: para
                   };
    
    NSRange range = [formatted rangeOfString:title];
    if (range.location != NSNotFound) {
        [attrs addAttributes:attributes range:range];
    }
    
    label.attributedText = attrs;
    [label sizeToFit];
    
    return label;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    return [self collectionView:collectionView cellForItemAtIndexPath:indexPath item:item];
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath item:(FeedItem *)item {
    
    ArticleCellB *cell = (ArticleCellB *)[collectionView dequeueReusableCellWithReuseIdentifier:kiPadArticleCell forIndexPath:indexPath];
    
    if (item != nil) {
        [cell configure:item customFeed:self.customFeed sizeCache:self.sizeCache];
    }
    
    if (cell.delegate == nil || cell.delegate != self) {
        cell.delegate = self;
    }
    
    [cell setupAppearance];
    
    BOOL showSeparator = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone || self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    [cell showSeparator:showSeparator];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if (self->_shouldShowHeader && [kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        DetailFeedHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailFeedHeaderView forIndexPath:indexPath];
        
        [view setupAppearance];
        
        self.headerView = view.headerContent;
        [self setupHeaderView];
        
        return view;
        
    }
    
    return nil;
    
}

#pragma mark - <ArticleCellDelegate>

- (void)didTapTag:(NSString *)tag {
    
    TagFeedVC *vc = [[TagFeedVC alloc] initWithTag:tag];
    
    [self showViewController:vc sender:self];
    
}

- (void)didTapMenuButton:(id)sender forArticle:(FeedItem *)article cell:(ArticleCellB *)cell {
    
    if(@available(iOS 13, *)) {
        [self _os12_didTapMenuButton:sender forArticle:article cell:cell];
    }
    else {
        [self _os12_didTapMenuButton:sender forArticle:article cell:cell];
    }
    
}

- (void)didTapTest:(id)sender {
    
}

- (void)_os12_didTapMenuButton:(id)sender forArticle:(FeedItem *)article cell:(ArticleCellB *)cell {
    
    if (article == nil) {
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        
        if (indexPath == nil) {
            return;
        }
        
    }
    
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
    
    if (article.isRead) {
        [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Mark Unread" image:[UIImage imageNamed:@"menu-unread"] color:[UIColor greenColor] didSelect:^(id<PopMenuAction> _Nonnull action) {
            
            [self userMarkedArticle:article read:NO];
            
        }]];
    }
    else {
        
        [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Mark Read" image:[UIImage imageNamed:@"menu-read"] color:[UIColor greenColor] didSelect:^(id<PopMenuAction> _Nonnull action) {
            
            [self userMarkedArticle:article read:YES];
            
        }]];
        
    }
    
    if (article.isBookmarked) {
        [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Unbookmark" image:[UIImage imageNamed:@"menu-unbookmark"] color:[UIColor greenColor] didSelect:^(id<PopMenuAction> _Nonnull action) {
            
            [self userMarkedArticle:article bookmarked:NO];
            
        }]];
    }
    else {
        
        [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Bookmark" image:[UIImage imageNamed:@"menu-bookmark"] color:[UIColor greenColor] didSelect:^(id<PopMenuAction> _Nonnull action) {
            
            [self userMarkedArticle:article bookmarked:YES];
            
        }]];
        
    }
    
    [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Browser" image:[UIImage imageNamed:@"open_in_browser"] color:[UIColor greenColor] didSelect:^(id<PopMenuAction> _Nonnull action) {
        
        NSURL *URL = formattedURL(@"yeti://external?link=%@", article.articleURL);
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
            
        });
        
    }]];
    
    [actions addObject:[[PopMenuDefaultAction alloc] initWithTitle:@"Share" image:[UIImage imageNamed:@"menu-share"] color:[UIColor blueColor] didSelect:^(id  _Nonnull action) {
        
        NSString *title = article.articleTitle;
        NSURL *URL = formattedURL(@"%@", article.articleURL);
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, URL] applicationActivities:nil];
        
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.sourceView = sender;
        pvc.sourceRect = [(UIView *)sender frame];
        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        
        [self presentViewController:avc animated:YES completion:nil];
        
    }]];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    PopMenuAppearance *appearance = [PopMenuAppearance new];
    appearance.popMenuCornerRadius = 12.f;
    appearance.popMenuColor = theme.menuColor;
    appearance.popMenuTextColor = theme.menuTextColor;
    
    appearance.popMenuFont = [TypeFactory.shared boldBodyFont];
    
    PopMenuViewController *vc = [[PopMenuViewController alloc] initWithAppearance:appearance sourceView:sender actions:actions];
    
    DDLogDebug(@"Button:%@\nArticle:%@\nCell:%@", sender, article.articleTitle, [self.collectionView indexPathForCell:cell]);
    
    [self presentViewController:vc animated:YES completion:nil];
    
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return;
    }
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    vc.providerDelegate = self;
    
    if (self.splitViewController == nil) {
        // in a modal stack
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.splitViewController != nil) {
        
        if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            
            if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                
                [self.splitViewController showDetailViewController:nav sender:self];
            }
            
        }
        else {
            [self showViewController:vc sender:self];
        }
        
    }
    else {
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {

    NSValue *value = self.sizeCache.count < indexPath.item ? [self.sizeCache safeObjectAtIndex:indexPath.item] : nil;

    if (value != nil) {
        CGSize size = [value CGSizeValue];
        if (size.width == self.flowLayout.estimatedItemSize.width) {
            return size;
        }
    }

    CGRect frame = CGRectZero;
    frame.size = self.flowLayout.estimatedItemSize;

    if (_protoCell == nil) {
        UINib *nib = [UINib nibWithNibName:NSStringFromClass([ArticleCellB class]) bundle:nil];
        _protoCell = [[nib instantiateWithOwner:_protoCell options:nil] objectAtIndex:0];
    }

    _protoCell.frame = frame;

    [_protoCell awakeFromNib];
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    CGSize size = frame.size;
    
    if (item != nil) {
        [_protoCell configure:item customFeed:self.customFeed sizeCache:nil];
        
        if (_protoCell->_isShowingCover == NO && _protoCell->_isShowingTags == NO) {
            size.height = [[_protoCell mainStackView] sizeThatFits:frame.size].height + 12.f;
        }
        else {
            size = [_protoCell.contentView systemLayoutSizeFittingSize:frame.size];
            size.height = floor(size.height) + 1.f;
        }
        
        self.sizeCache[indexPath.item] = [NSValue valueWithCGSize:size];
        
        [_protoCell prepareForReuse];

    }

    return size;

}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)) {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return nil;
    }
    
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"feedItem-%@", @(item.hash)) previewProvider:nil actionProvider:^UIMenu<UIAction *> * _Nullable(NSArray<UIMenuElement<UIAction *> *> * _Nonnull suggestedActions) {
       
        UIAction *read = nil;
        
        if (item.isRead == YES) {
            
            read = [UIAction actionWithTitle:@"Unread" image:[UIImage systemImageNamed:@"circle"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item read:NO];
                
            }];
            
        }
        else {
            read = [UIAction actionWithTitle:@"Read" image:[UIImage systemImageNamed:@"circle.fill"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item read:YES];
                
            }];
        }
        
        UIAction *bookmark = nil;
        
        if (item.isBookmarked == YES) {
            
            bookmark = [UIAction actionWithTitle:@"Unbookmark" image:[UIImage systemImageNamed:@"bookmark"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
            
                [self userMarkedArticle:item bookmarked:NO];
                
            }];
            
        }
        else {
            bookmark = [UIAction actionWithTitle:@"Bookmark" image:[UIImage systemImageNamed:@"bookmark.fill"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
                
                [self userMarkedArticle:item bookmarked:YES];
                
            }];
        }
        
        UIAction *browser = [UIAction actionWithTitle:@"Open in Browser" image:[UIImage systemImageNamed:@"safari"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
        
            NSURL *URL = formattedURL(@"yeti://external?link=%@", item.articleURL);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
                
            });
            
        }];
        
        UIAction *share = [UIAction actionWithTitle:@"Share Article" image:[UIImage systemImageNamed:@"square.and.arrow.up"] options:kNilOptions handler:^(__kindof UIAction * _Nonnull action) {
            
            NSString *title = item.articleTitle;
            NSURL *URL = formattedURL(@"%@", item.articleURL);
            
            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, URL] applicationActivities:nil];
            
            UIPopoverPresentationController *pvc = avc.popoverPresentationController;
            pvc.sourceView = self.collectionView;
            pvc.sourceRect = [[self.collectionView cellForItemAtIndexPath:indexPath] frame];
            
            [self presentViewController:avc animated:YES completion:nil];
            
        }];
        
        return [UIMenu actionMenuWithTitle:@"Article Actions" children:@[read, bookmark, browser, share]];
        
    }];
    
    return config;
    
}

#pragma mark - <UICollectionViewDataSourcePrefetching>

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) { @autoreleasepool {
       
        FeedItem *item = [self itemForIndexPath:indexPath];
        
        if (item == nil) {
            continue;
        }
        
        if (item.coverImage == nil) {
            continue;
        }
        
        if (self.prefetchedImageTasks[item.coverImage] != nil) {
            continue;
        }
        
        NSURLSessionTask *task = [SharedImageLoader downloadImageForURL:item.coverImage success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
//            DDLogDebug(@"Cached image for %@", item.coverImage);
            
            [self.prefetchedImageTasks removeObjectForKey:item.coverImage];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [self.prefetchedImageTasks removeObjectForKey:item.coverImage];
            
        }];
        
        self.prefetchedImageTasks[item.coverImage] = task;
        
    } }
    
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) { @autoreleasepool {
        
        FeedItem *item = [self itemForIndexPath:indexPath];
        
        if (item == nil) {
            continue;
        }
        
        if (item.coverImage == nil) {
            continue;
        }
        
        NSURLSessionDataTask *task = self.prefetchedImageTasks[item.coverImage];
        
        if (task == nil) {
            continue;
        }
        
        [task cancel];
        
        [self.prefetchedImageTasks removeObjectForKey:item.coverImage];
        
    } }
    
}

#pragma mark - <ScrollLoading>

- (void)loadNextPage {
    
    if (@available(iOS 13, *)) {
        if (self.controllerState == StateLoading) {
            return;
        }
    }
    else {
        if (self.DS.state == DZDatasourceLoading) {
            return;
        }
    }
    
    if (self->_ignoreLoadScroll)
        return;
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    if (@available(iOS 13, *)) {
        self.controllerState = StateLoading;
    }
    else {
        self.DS.state = DZDatasourceLoading;
    }
    
    weakify(self);
    
    NSInteger page = self->_page + 1;
    
    YetiSortOption sorting = self.isExploring ? YTSortAllDesc : SharedPrefs.sortingOption;
    
    [MyFeedsManager getFeed:self.feed sorting:sorting page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self->_page = page;
        
        if (responseObject == nil || responseObject.count == 0) {
            self->_canLoadNext = NO;
        }
        else {
            weakify(self);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                
                NSArray *articles = page == 1 ? @[] : (self.feed.articles ?: @[]);
                articles = [articles arrayByAddingObjectsFromArray:responseObject];
                self.feed.articles = articles;
                self->_ignoreLoadScroll = YES;
                
                @try {
                    
                    if (@available(iOS 13, *)) {
                        NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
                        [snapshot appendItemsWithIdentifiers:responseObject intoSectionWithIdentifier:ArticlesSection];
                        
                        [self.DDS applySnapshot:snapshot animatingDifferences:YES];
                    }
                    else {
                        self.DS.data = self.feed.articles;
                    }
                }
                @catch (NSException *exc) {
                    DDLogWarn(@"Exception updating feed articles: %@", exc);
                }
                
            });
        }
        
        self->_page = page;
        
        if ([self loadOnReady] != nil) {
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                [self loadArticle];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if (self->_ignoreLoadScroll) {
                self->_ignoreLoadScroll = NO;
            }
            
            if (@available(iOS 13, *)) {
                self.controllerState = StateLoaded;
            }
            else {
                self.DS.state = DZDatasourceLoaded;
            }
        });
        
        if (page == 1 && self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self loadNextPage];
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        if (!self)
            return;
        
        if (@available(iOS 13, *)) {
            self.controllerState = StateErrored;
        }
        else {
            self.DS.state = DZDatasourceError;
        }
    }];
}

- (BOOL)cantLoadNext
{
    return !_canLoadNext;
}

#pragma mark - <ArticleProvider>

- (void)willChangeArticle {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
    });
}

// the logic for the following two methods is inversed
// since the articles are displayed in reverse chronological order
- (BOOL)hasNextArticleForArticle:(FeedItem *)item {
    
    NSUInteger index = [self indexOfItem:item retIndexPath:nil];
    
    if (index == NSNotFound)
        return NO;
    
    return index > 0;
}

- (BOOL)hasPreviousArticleForArticle:(FeedItem *)item {
    
    NSUInteger index = [self indexOfItem:item retIndexPath:nil];
    
    if (index == NSNotFound)
        return NO;
    
    NSInteger count = 0;
    
    if (@available(iOS 13, *)) {
        count = self.DDS.snapshot.numberOfItems;
    }
    else {
        count = ((NSArray <FeedItem *> *)self.DS.data).count;
    }
    
    return (index < (count - 1));
}

- (FeedItem *)previousArticleFor:(FeedItem *)item {
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    if (index != NSNotFound && index > 0) {
        index--;
        
        [self willChangeArticle];
        
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return [self itemForIndexPath:indexPath];
    }
    
    return nil;
}

- (FeedItem *)nextArticleFor:(FeedItem *)item {
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    NSInteger count = 0;
    
    if (@available(iOS 13, *)) {
        count = self.DDS.snapshot.numberOfItems;
    }
    else {
        count = ((NSArray <FeedItem *> *)self.DS.data).count;
    }
    
    if (index < (count - 1)) {
        index++;
        
        [self willChangeArticle];
        
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return [self itemForIndexPath:indexPath];
    }
    
    return nil;
}

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read {
    
    if (article == nil)
        return;
    
    __block NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:article retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    if (indexPath == nil) {
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.read = read;
        }
        
        FeedItem *articleInDS = [self itemForIndexPath:indexPath];
        
        if (@available(iOS 13, *)) {
            if (articleInDS == nil) {
                articleInDS = [self.DDS.snapshot.itemIdentifiers objectAtIndex:index];
            }
        }
        
        if (articleInDS != nil) {
            articleInDS.read = read;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.item == index) {
                    isVisible = YES;
                    indexPath = ip;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
                // only change when not bookmarked. If bookmarked, continue showing the bookmark icon
                if (cell != nil && article.isBookmarked == NO) {
                    
                    cell.markerView.image = [[UIImage imageNamed:@"munread"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    
                    if (read == YES) {
                        cell.markerView.tintColor = [[YTThemeKit theme] borderColor];
                    }
                    else {
                        cell.markerView.tintColor = [[YTThemeKit theme] tintColor];
                    }
                }
            }
        }
    });
}

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked {
    
    if (article == nil)
        return;
    
    __block NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:article retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    if (indexPath == nil) {
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.bookmarked = bookmarked;
        }
        
        FeedItem *articleInDS = [self itemForIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        
        if (@available(iOS 13, *)) {
            if (articleInDS == nil) {
                articleInDS = [self.DDS.snapshot.itemIdentifiers objectAtIndex:index];
            }
        }
        
        if (articleInDS != nil) {
            
            articleInDS.bookmarked = bookmarked;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.item == index) {
                    isVisible = YES;
                    indexPath = ip;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
                
                if (cell != nil) {
                    if (bookmarked == NO) {
                        cell.markerView.image = nil;
                    }
                    else {
                        cell.markerView.image = [UIImage imageNamed:@"mbookmark"];
                    }
                }
            }
        }
    });
    
}

- (void)didChangeToArticle:(FeedItem *)item {
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didChangeToArticle:item];
        });
        
        return;
    }
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    indexPath = indexPath ?: [NSIndexPath indexPathForRow:index inSection:0];
    
    if ((self.class != NSClassFromString(@"CustomFeedVC")
         || self.class != NSClassFromString(@"CustomFolderVC")
         || self.class != NSClassFromString(@"CustomAuthorVC"))
        && !item.isRead) {
        [self userMarkedArticle:item read:YES];
    }
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        [self scrollViewDidEndDecelerating:self.collectionView];
    });
}

#pragma mark - State Restoration

NSString * const kBFeedData = @"FeedData";
NSString * const kBCurrentPage = @"FeedsLoadedPage";
NSString * const kSizCache = @"FeedSizesCache";

+ (nullable UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Feed *feed = [coder decodeObjectForKey:kBFeedData];
    
    if (feed) {
        DetailFeedVC *vc = [[DetailFeedVC alloc] initWithFeed:feed];
        
        return vc;
    }
    
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.feed forKey:kBFeedData];
    [coder encodeInteger:_page forKey:kBCurrentPage];
    [coder encodeObject:self.sizeCache forKey:kSizCache];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
    if ([NSStringFromClass(self.class) isEqualToString:NSStringFromClass(DetailFeedVC.class)] == YES) {
        Feed *feed = [coder decodeObjectForKey:kBFeedData];
        
        if (feed) {
            [self setupLayout];
            
            self.feed = feed;
            
            if (@available(iOS 13, *)) {
                
                NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
                [snapshot appendItemsWithIdentifiers:self.feed.articles intoSectionWithIdentifier:ArticlesSection];
                
                [self.DDS applySnapshot:snapshot animatingDifferences:NO];
            }
            else {
                [self.DS resetData];
                self.DS.data = self.feed.articles;
            }
            
        }
    }
    
    _page = [coder decodeIntegerForKey:kBCurrentPage];
    NSArray *sizesCache = [coder decodeObjectForKey:kSizCache];
    
    if (sizesCache) {
        self.sizeCache = sizesCache.mutableCopy;
    }
    
}

#pragma mark - Layout

- (BOOL)showsSortingButton {
    return YES;
}

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    // Subscribe Button appears in the navigation bar
    if (self.isExploring == YES) {
        return @[];
    }
 
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"done_all"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:)];
    allRead.accessibilityValue = @"Mark all articles as read";
    allRead.accessibilityHint = @"Mark all current articles as read.";
    allRead.width = 32.f;
    
    UIBarButtonItem *allReadBackDated = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"done_all_bd"] style:UIBarButtonItemStylePlain target:self action:@selector(didLongPressOnAllRead:)];
    allReadBackDated.accessibilityValue = @"Mark all articles as read";
    allReadBackDated.accessibilityHint = @"Mark all articles as well as backdated articles as read.";
    allReadBackDated.width = 32.f;
    
    
    // sorting button
    YetiSortOption option = SharedPrefs.sortingOption;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL isUnread = NSSelectorFromString(@"isUnread");
    
    if (self.customFeed == FeedTypeCustom && [self respondsToSelector:isUnread] && (BOOL)[self performSelector:isUnread] == YES) {
        
        // when the active option is either of these two, we don't need
        // to do anything extra
        if (option != YTSortUnreadAsc && option != YTSortUnreadDesc) {
            
            // map it to whatever the selected option is
            if (option == YTSortAllAsc) {
                option = YTSortUnreadAsc;
            }
            else if (option == YTSortAllDesc) {
                option = YTSortUnreadDesc;
            }
            
        }
        
    }
#pragma clang diagnostic pop
    
    UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:[SortImageProvider imageForSortingOption:option] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSortOptions:)];
    sorting.width = 32.f;
    
    if (!(self.feed.hubSubscribed && self.feed.hub)) {
        NSMutableArray *buttons = @[allReadBackDated, allRead].mutableCopy;
        
        if ([self showsSortingButton]) {
            [buttons addObject:sorting];
        }
        
        return buttons;
    }
    else {
        // push notifications are possible
        NSString *imageString = self.feed.isSubscribed ? @"notifications_on" : @"notifications_off";
        
        UIBarButtonItem *notifications = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageString] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNotifications:)];
        notifications.accessibilityValue = self.feed.isSubscribed ? @"Subscribe" : @"Unsubscribe";
        notifications.accessibilityHint = self.feed.isSubscribed ? @"Unsubscribe from notifications" : @"Subscribe to notifications";
        notifications.width = 32.f;
        
        NSMutableArray *buttons = @[allReadBackDated, allRead, notifications].mutableCopy;
        
        if ([self showsSortingButton]) {
            [buttons addObject:sorting];
        }
        
        return buttons;
    }
    
}

- (void)setupNavigationBar {
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    if (self.isExploring) {
        // check if the user is subscribed to this feed
        Feed *existing = [MyFeedsManager feedForID:self.feed.feedID];
        if (!existing) {
            // allow subscription
            UIBarButtonItem *subscribe = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStyleDone target:self action:@selector(subscribeToFeed:)];
            subscribe.accessibilityValue = @"Subscribe to this feed";
            self.navigationItem.rightBarButtonItem = subscribe;
        }
    }
    else {
        
        if (PrefsManager.sharedInstance.useToolbar == NO) {
            self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
            
            self.navigationController.toolbarHidden = YES;
        }
        else {
            self.navigationController.toolbarHidden = NO;
        }
        
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (@available(iOS 13, *)) {}
    else {
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height, self.navigationController.navigationBar.bounds.size.width, height)];
        hairline.backgroundColor = theme.cellColor;
        hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        
        [self.navigationController.navigationBar addSubview:hairline];
        self.hairlineView = hairline;
    }
    
}

- (NSArray <UIBarButtonItem *> *)toolbarItems {
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        return nil;
    }
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 24.f;
    
    NSArray *right = [[self.rightBarButtonItems rz_map:^id(UIBarButtonItem *obj, NSUInteger idx, NSArray *array) {
        
        if (idx == 0) {
            return obj;
        }
        
        return @[flex, obj];
        
    }] rz_flatten];
    
    return right;
}

- (void)setupLayout {
    
    BOOL isCompact = [[[self.collectionView valueForKeyPath:@"delegate"] traitCollection] horizontalSizeClass] == UIUserInterfaceSizeClassCompact;
    
    CGFloat padding = isCompact ? 0 : [self.flowLayout minimumInteritemSpacing];
    
    if (@available(iOS 13, *)) {
        
        NSCollectionLayoutSize *layoutSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f] heightDimension:[NSCollectionLayoutDimension estimatedDimension:90.f]];
        
        NSCollectionLayoutItem *layoutItem = [NSCollectionLayoutItem itemWithLayoutSize:layoutSize];
        
        if (isCompact == NO) {
            
            layoutItem.edgeSpacing = [NSCollectionLayoutEdgeSpacing spacingForLeading:[NSCollectionLayoutSpacing flexibleSpacing:LayoutPadding] top:nil trailing:[NSCollectionLayoutSpacing flexibleSpacing:LayoutPadding] bottom:nil];
            
        }
        
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f] heightDimension:[NSCollectionLayoutDimension estimatedDimension:90.f]];
        
        NSInteger columnCount = isCompact ? 1 : 2;
        
        NSCollectionLayoutGroup *layoutGroup = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitem:layoutItem count:columnCount];
        
        if (isCompact == NO) {
            layoutGroup.interItemSpacing = [NSCollectionLayoutSpacing flexibleSpacing:LayoutPadding];
        }
        
        NSCollectionLayoutSection *layoutSection = [NSCollectionLayoutSection sectionWithGroup:layoutGroup];
        
        if (isCompact == NO) {
            layoutSection.contentInsets = NSDirectionalEdgeInsetsMake(0, LayoutPadding, 0, LayoutPadding);
        }
        
        if (self->_shouldShowHeader == YES) {
            
            NSCollectionLayoutSize *boundrySize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f] heightDimension:[NSCollectionLayoutDimension estimatedDimension:84.f]];

            NSCollectionLayoutBoundarySupplementaryItem *boundryItem = [NSCollectionLayoutBoundarySupplementaryItem supplementaryItemWithLayoutSize:boundrySize elementKind:UICollectionElementKindSectionHeader containerAnchor:[NSCollectionLayoutAnchor layoutAnchorWithEdges:NSDirectionalRectEdgeTop]];
            
            boundryItem.zIndex = 10;

            layoutSection.boundarySupplementaryItems = @[boundryItem];
            layoutSection.contentInsets = NSDirectionalEdgeInsetsMake(90.f, 0, 0, 0);
            
        }

        UICollectionViewCompositionalLayout *compLayout = [[UICollectionViewCompositionalLayout alloc] initWithSection:layoutSection];
        
        [self.collectionView setCollectionViewLayout:compLayout animated:NO];
        
        self.compLayout = (UICollectionViewCompositionalLayout *)[self.collectionView collectionViewLayout];
        
        return;
    }
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        self.flowLayout.sectionInset = UIEdgeInsetsMake(12.f, 0.f, 12.f, 0.f);
        self.flowLayout.minimumLineSpacing = 0.1f;
        self.flowLayout.minimumInteritemSpacing = 0.1f;
        
    }
    else {
        
        self.flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
        self.flowLayout.minimumLineSpacing = padding;
        self.flowLayout.minimumInteritemSpacing = padding;
        
    }
    
    self.collectionView.layoutMargins = UIEdgeInsetsZero;

    CGSize contentSize = self.collectionView.bounds.size;

    if (CGSizeEqualToSize(contentSize, CGSizeZero)) {
        contentSize = [UIScreen mainScreen].bounds.size;
    }

    CGFloat width = contentSize.width;

    /*
     On iPads (Regular)
     |- 16 - (cell) - 16 - (cell) - 16 -|
     */

    /*
     On iPhones (Compact)
     |- 0 - (cell) - 0 -|
     */

    CGFloat totalPadding =  padding * 3.f;

    CGFloat usableWidth = width - totalPadding;

    CGFloat cellWidth = usableWidth;

    if (usableWidth > 601.f) {
        // the remainder will be absorbed by the interimSpacing
        cellWidth = floor(usableWidth / 2.f);
    }
    else {
        cellWidth = width - (padding * 2.f);
    }

    self.flowLayout.estimatedItemSize = CGSizeMake(cellWidth, 90.f);
    self.flowLayout.itemSize = UICollectionViewFlowLayoutAutomaticSize;

    if (self->_shouldShowHeader) {
        self.flowLayout.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 80.f);
    }
    else {
        self.flowLayout.headerReferenceSize = CGSizeZero;
    }
    
    [self.flowLayout invalidateLayout];
    
}

- (void)setupHeaderView {
    
    if (_headerView == nil)
        return;
    
    if (_headerView.delegate && _headerView.delegate == self) {
        return;
    }
    
    [self.headerView configure:self.feed];
    self.headerView.delegate = self;
    
//    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        return UIModalPresentationPopover;
    }
    
    return UIModalPresentationNone;
}


#pragma mark - <FeedHeaderViewDelegate>

- (void)didTapAuthor:(Author *)author
{
    DetailAuthorVC *vc = [[DetailAuthorVC alloc] initWithFeed:self.feed];
    vc.author = author;
    vc.customFeed = self.customFeed;
    
    [self showViewController:vc sender:self];
}

#pragma mark - KVO / Actions

- (void)didChangeTheme {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.cellColor;
    self.collectionView.backgroundColor = theme.cellColor;
    
    if (@available(iOS 13, *)) {}
    else {
        
        
        
        if (self.hairlineView != nil) {
            self.hairlineView.backgroundColor = theme.cellColor;
        }
    }
    
    [self reloadHeaderView];
    
}

- (void)reloadHeaderView {
    
    [(DetailFeedHeaderView *)[self.headerView superview] setupAppearance];
    
}

- (void)didChangeContentCategory {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sizeCache = @[].mutableCopy;
        [self setupLayout];
    });
    
    if ([[self.collectionView indexPathsForVisibleItems] count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        });
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:propSel(frame)] && context == KVO_DetailFeedFrame) {
        
        CGRect old = [[change valueForKey:NSKeyValueChangeOldKey] CGRectValue];
        CGRect new = [[change valueForKey:NSKeyValueChangeNewKey] CGRectValue];
        
        if (CGRectEqualToRect(old, new) == NO) {
        
            [self didChangeContentCategory];
            
        }
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
