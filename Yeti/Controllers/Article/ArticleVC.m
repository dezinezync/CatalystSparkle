//
//  ArticleVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import "FeedsManager+KVS.h"
#import "Content.h"

#import "Paragraph.h"
#import "Heading.h"
#import "Blockquote.h"
#import "List.h"
#import "Aside.h"
#import "Youtube.h"
#import "Image.h"
#import "Gallery.h"
#import "Linebreak.h"
#import "Code.h"
#import "Tweet.h"

#import "YetiConstants.h"
#import "CheckWifi.h"

#import <DZNetworking/UIImageView+ImageLoading.h>
#import "NSAttributedString+Trimming.h"
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>
#import "NSDate+DateTools.h"
#import "NSString+HTML.h"
#import "NSString+Levenshtein.h"
#import "CodeParser.h"

#import "TypeFactory.h"

#import <SafariServices/SafariServices.h>

#import "YetiThemeKit.h"
#import "YTPlayer.h"
#import "YTExtractor.h"
#import "NSString+ImageProxy.h"

static void *KVO_PlayerRate = &KVO_PlayerRate;

typedef NS_ENUM(NSInteger, ArticleState) {
    ArticleStateUnknown,
    ArticleStateLoading,
    ArticleStateLoaded,
    ArticleStateError,
    ArticleStateEmpty
};

@interface ArticleVC () <UIScrollViewDelegate, UITextViewDelegate, UIViewControllerRestoration, AVPlayerViewControllerDelegate> {
    BOOL _hasRendered;
    
    BOOL _isQuoted;
    
    BOOL _deferredProcessing;
    
    BOOL _isRestoring;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottom;
@property (weak, nonatomic) UIView *last; // reference to the last setup view.
@property (weak, nonatomic) id nextItem; // next item which will be processed
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;
@property (nonatomic, strong) NSPointerArray *images;

@property (nonatomic, strong) NSPointerArray *videos;

@property (nonatomic, strong) CodeParser *codeParser;

@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, assign) ArticleState state;

@property (nonatomic, strong) NSError *articleLoadingError;
@property (weak, nonatomic) IBOutlet UILabel *errorTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIStackView *errorStackView;

@property (nonatomic, strong) YTExtractor *ytExtractor;

@end

@implementation ArticleVC

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (instancetype)initWithItem:(FeedItem *)item
{
    if (self = [super initWithNibName:NSStringFromClass(ArticleVC.class) bundle:nil]) {
        self.item = item;
        
        self.restorationIdentifier = formattedString(@"%@-%@", NSStringFromClass(self.class), item.identifier);
        self.restorationClass = self.class;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.state = ArticleStateLoading;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(0.f, 0.f, 44.f, 0.f);
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        || self.splitViewController.view.bounds.size.height < 814.f) {
        
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 88.f, 0);
        
        self.scrollView.contentInset = UIEdgeInsetsMake(LayoutPadding * 2, 0, 0, 0);
        
    }
    else if (self.splitViewController.view.bounds.size.height > 814.f
             && self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(16.f, 0.f, 52.f, 0.f);
        
    }
    
    self.scrollView.restorationIdentifier = self.restorationIdentifier;
    
    [self didUpdateTheme];
    
    UILayoutGuide *readable = self.scrollView.readableContentGuide;
    
    [self setupHelperView];
    
    [self.stackView.leadingAnchor constraintEqualToAnchor:readable.leadingAnchor constant:LayoutPadding/2.f].active = YES;
    [self.stackView.trailingAnchor constraintEqualToAnchor:readable.trailingAnchor constant:-LayoutPadding/2.f].active = YES;
    
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    weakify(self);
    
    if (!(self.item != nil && self.item.content != nil && self.item.isBookmarked == YES)) {
        
        // this ensures that bookmarked articles render the title.
        // when this runs, the title has already been added to the view
        // the following lines would remove it.
        
        [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            strongify(self);
            [self.stackView removeArrangedSubview:obj];
            [obj removeFromSuperview];
            
        }];
    }
    
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView layoutIfNeeded];
    
    [self.stackView setNeedsUpdateConstraints];
    [self.stackView layoutIfNeeded];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidHideNotification object:nil];
    [center addObserver:self selector:@selector(didChangePreferredContentSize) name:UserUpdatedPreferredFontMetrics object:nil];
    [center addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    
    self.state = (self.item.content && self.item.content.count) ? ArticleStateLoaded : ArticleStateLoading;
    
    self.ytExtractor = [[YTExtractor alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    if (!_hasRendered) {
        [self.loader startAnimating];
    }
    
    if (!self.hairlineView) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        UINavigationBar *navbar = self.navigationController.navigationBar;
        
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, navbar.bounds.size.height, navbar.bounds.size.width, height)];
        hairline.backgroundColor = theme.cellColor;
        hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        
        [navbar addSubview:hairline];
        self.hairlineView = hairline;
    }
    
    [MyFeedsManager checkConstraintsForRequestingReview];
}

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//
//    if (_hasRendered == YES)
//        return;
//
//    _hasRendered = YES;
//
//    if (self.item.content == nil || [self.item.content count] == 0) {
//        [self setupArticle:self.item];
//    }
//    else {
//        [self _setupArticle:self.item start:[NSDate date] isChangingArticle:NO];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSCache *cache = [SharedImageLoader valueForKeyPath:@"cache"];
    
    if (cache) {
        [cache removeAllObjects];
    }
    
//    [self.navigationController popViewControllerAnimated:NO];
}

- (void)viewSafeAreaInsetsDidChange
{
    if (UIScreen.mainScreen.scale == 3.f && self.view.bounds.size.height > 667.f) {
        self.scrollBottom.constant = -self.view.safeAreaInsets.bottom;
    }
    else {
        self.scrollBottom.constant = 0;
    }
    
    [super viewSafeAreaInsetsDidChange];
}

- (void)dealloc {
    NSCache *cache = [SharedImageLoader valueForKeyPath:@"cache"];
    
    if (cache) {
        [cache removeAllObjects];
    }
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    } @catch (NSException *exc) {}
}

#pragma mark -

- (void)setupHelperView {
    
    if (self.providerDelegate == nil)
        return;
    
    ArticleHelperView *helperView = [[ArticleHelperView alloc] initWithNib];
    helperView.frame = CGRectMake((self.view.bounds.size.width - 190.f) / 2.f, self.view.bounds.size.height - 44.f - 32.f, 190.f, 44.f);
    
    UIUserInterfaceIdiom idiom = self.traitCollection.userInterfaceIdiom;
    UIUserInterfaceSizeClass sizeClass = self.traitCollection.horizontalSizeClass;
    
    [self.view addSubview:helperView];
    
    if (idiom == UIUserInterfaceIdiomPad && sizeClass == UIUserInterfaceSizeClassRegular) {
        // on iPad, wide
        // we also push it slightly lower to around where the hands usually are on iPads
        [helperView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:(self.view.bounds.size.height / 4.f)].active = YES;
        [helperView.heightAnchor constraintEqualToConstant:190.f].active = YES;
        [helperView.widthAnchor constraintEqualToConstant:44.f].active = YES;
        helperView.bottomConstraint = [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-LayoutPadding];
        
        helperView.bottomConstraint.active = YES;
        helperView.stackView.axis = UILayoutConstraintAxisVertical;
        
        // since we're modifying the bounds, update the shadow path
        [helperView setNeedsUpdateConstraints];
        [helperView layoutIfNeeded];
        [helperView updateShadowPath];
    }
    else {
        // in compact mode
        [helperView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
        [helperView.widthAnchor constraintEqualToConstant:190.f].active = YES;
        [helperView.heightAnchor constraintEqualToConstant:44.f].active = YES;
        helperView.bottomConstraint = [helperView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-32.f];
        helperView.bottomConstraint.active = YES;
    }
    
    _helperView = helperView;
    _helperView.handlerDelegate = self;
    _helperView.providerDelegate = self.providerDelegate;
    
    [self setupHelperViewActions];
}

- (void)setupHelperViewActions {
    if (self.providerDelegate == nil)
        return;
    
    BOOL next = [self.providerDelegate hasPreviousArticleForArticle:self.item];
    BOOL previous = [self.providerDelegate hasNextArticleForArticle:self.item];
    
    [self.helperView.previousArticleButton setEnabled:previous];
    
    [self.helperView.nextArticleButton setEnabled:next];
    
    self.helperView.startOfArticle.enabled = NO;
    self.helperView.endOfArticle.enabled = YES;
}

#pragma mark -

- (void)didUpdateTheme {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(didUpdateTheme) withObject:nil waitUntilDone:NO];
        return;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.loader.color = theme.captionColor;
    self.loader.tintColor = theme.captionColor;
    
    self.view.backgroundColor = theme.articleBackgroundColor;
    self.scrollView.backgroundColor = theme.articleBackgroundColor;
    
    if (self.hairlineView != nil) {
        self.hairlineView.backgroundColor = theme.articleBackgroundColor;
    }
    
    if (self.helperView != nil) {
        self.helperView.backgroundColor = theme.articlesBarColor;
        self.helperView.tintColor = theme.tintColor;
        [self.helperView updateShadowPath];
    }
    
    [self setupArticle:self.currentArticle];
    
}

- (void)didChangePreferredContentSize {
    
    if (self.state == ArticleStateLoading) {
        return;
    }
    
    Paragraph.paragraphStyle = nil;
    
    [self setupArticle:self.currentArticle];
    
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    weakify(self);
    
    if (coordinator) {
        [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            strongify(self);
            
            [self setupToolbar:newCollection];
        }];
    }
    else
        [self setupToolbar:newCollection];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:Paragraph.class]) {
            Paragraph *para = obj;
            
            if (para.isCaption == NO && para.isAccessibilityElement == NO) {
                para.accessibileElements = nil;
            }
            
        }
        
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (CGSizeEqualToSize(self.view.bounds.size, size))
        return;
    
    // get the first visible view
    NSArray <UIView *> *visibleViews = [self visibleViews];
    UIView *firstVisible = nil;
    
    if (visibleViews != nil && [visibleViews count]) {
        firstVisible = [visibleViews firstObject];
    }
    
    weakify(self);

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
        strongify(self);
        
        [self.helperView removeFromSuperview];

        for (Image *imageView in self.images) { @autoreleasepool {
            if ([imageView respondsToSelector:@selector(imageView)] && imageView.imageView.image) {
                [imageView invalidateIntrinsicContentSize];
                [imageView.imageView invalidateIntrinsicContentSize];
                [imageView.imageView updateAspectRatioWithImage:imageView.imageView.image];
            }
            else if ([imageView respondsToSelector:@selector(image)] && [(UIImageView *)imageView image]) {
                [(SizedImage *)imageView updateAspectRatioWithImage:[(UIImageView *)imageView image]];
                [imageView invalidateIntrinsicContentSize];
            }
        } }
        
        [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj isKindOfClass:Paragraph.class] && [(Paragraph *)obj isBigContainer]) {
                
                [(Paragraph *)obj setAccessibileElements:nil];
                
            }
            if ([obj isKindOfClass:Tweet.class]) {
                [(Tweet *)obj invalidateIntrinsicContentSize];
            }
        }];

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        strongify(self);
        
        [self setupHelperView];
        [self scrollViewDidScroll:self.scrollView];
        
        if (firstVisible) {
            CGFloat yOffset = firstVisible.frame.origin.y + (self.scrollView.bounds.size.height / 2);
            [self.scrollView setContentOffset:CGPointMake(0, yOffset)];
        }
    }];
}

#pragma mark - <ArticleHandler>

- (void)setState:(ArticleState)state {
    
    if (_state == state) {
        return;
    }
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        asyncMain(^{
            strongify(self);
            [self setState:state];
        });
        return;
    }
    
    _state = state;
    
    switch (state) {
        case ArticleStateLoading:
        {
            self.errorStackView.hidden = YES;
            self.stackView.hidden = YES;
            
            if (self.loader.isHidden) {
                self.loader.hidden = NO;
                [self.loader startAnimating];
            }
            
            if (self.stackView.arrangedSubviews.count > 0) {
                weakify(self);
                
                [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    strongify(self);
                    [self.stackView removeArrangedSubview:obj];
                    [obj removeFromSuperview];
                    
                }];
            }
            
            if (self.scrollView.contentOffset.y > self.scrollView.adjustedContentInset.top) {
                [self.scrollView setContentOffset:CGPointMake(0, -self.scrollView.adjustedContentInset.top) animated:NO];
            }
            
            self.images = [NSPointerArray weakObjectsPointerArray];
            self.videos = [NSPointerArray strongObjectsPointerArray];
        }
            break;
        case ArticleStateLoaded:
        {
            self.errorStackView.hidden = YES;
            
            weakify(self);
            
            self.stackView.alpha = 0.f;
            self.stackView.hidden = NO;
            self.loader.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
            
            [UIView animateWithDuration:0.3 animations:^{
                
                strongify(self);
                
                [self.loader stopAnimating];
                self.loader.transform = CGAffineTransformMakeScale(0.25f, 0.25f);
                self.loader.alpha = 0.f;
                
                self.stackView.alpha = 1.f;
                self.stackView.transform = CGAffineTransformMakeScale(1.f, 1.f);
                
            } completion:^(BOOL finished) {
               
                strongify(self);
                
                self.loader.hidden = YES;
                self.loader.transform = CGAffineTransformMakeScale(1.f, 1.f);
                self.loader.alpha = 1.f;
                
                [self setupHelperViewActions];
                [self setupToolbar:self.traitCollection];
                
            }];
            
        }
            break;
        case ArticleStateError:
        {
            if (!self.articleLoadingError) {
                break;
            }
            
            [self.loader stopAnimating];
            self.loader.hidden = YES;
            
            self.stackView.hidden = YES;
            
            self.errorTitleLabel.text = @"Error loading the article";
            self.errorDescriptionLabel.text = [self.articleLoadingError localizedDescription];
            
            YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
            self.errorTitleLabel.textColor = theme.titleColor;
            self.errorDescriptionLabel.textColor = theme.captionColor;
            
            for (UILabel *label in @[self.errorTitleLabel, self.errorDescriptionLabel]) {
                label.backgroundColor = theme.articleBackgroundColor;
                label.opaque = YES;
            }
            
            self.errorStackView.hidden = NO;
            
            self.articleLoadingError = nil;
        }
            break;
        default:
            break;
    }
}

- (FeedItem *)currentArticle
{
    return self.item;
}

- (void)setupArticle:(FeedItem *)article
{
    if (!article)
        return;
    
    if (self.item) {
        
        if (self.item.isBookmarked == NO) {
            if (_isRestoring == YES) {
                _isRestoring = NO;
            }
            else {
                // only do this when not restoring state.
                self.item.content = nil;
            }
        }
    }
    
    BOOL isChangingArticle = self.item && self.item.identifier.integerValue != article.identifier.integerValue;
    
    self.item = article;
    
    NSDate *start = NSDate.date;
    
    if (self.item.content && self.item.content.count) {
        self.state = ArticleStateLoading;
        
        [self _setupArticle:self.item start:start isChangingArticle:isChangingArticle];
        return;
    }
    
    if (MyFeedsManager.reachability.currentReachabilityStatus == NotReachable) {
        NSError *error = [NSError errorWithDomain:@"ArticleInterface" code:500 userInfo:@{NSLocalizedDescriptionKey: @"Elytra cannot connect to the internet at the moment. Please check your connection and try again."}];
        self.articleLoadingError = error;
        self.state = ArticleStateError;
        return;
    }
    
    self.state = ArticleStateLoading;
    
    weakify(self);
    
    [MyFeedsManager getArticle:self.item.identifier success:^(FeedItem *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        // v1.2 will automatically mark the articles as read upon successfully fetching.
        [self updateFeedAndFolder:responseObject];
        
        [self _setupArticle:responseObject start:start isChangingArticle:isChangingArticle];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        strongify(self);
        
        self.articleLoadingError = error;
        self.state = ArticleStateError;
        
    }];
}

- (void)updateFeedAndFolder:(FeedItem *)item {
    
    Feed *feed = [MyFeedsManager feedForID:item.feedID];
    
    if (feed != nil) {
        
        feed.unread = @(MAX(0, feed.unread.integerValue - 1));
        
        if (feed.folderID != nil) {
            Folder *folder = [MyFeedsManager folderForID:feed.folderID];
            
            if (folder != nil) {
                [folder willChangeValueForKey:propSel(unreadCount)];
                // simply tell the unreadCount property that it has been updated.
                // KVO should handle the rest for us
                [folder didChangeValueForKey:propSel(unreadCount)];
            }
        }
        
    }
    
}

- (void)_setupArticle:(FeedItem *)responseObject start:(NSDate *)start isChangingArticle:(BOOL)isChangingArticle {
    
    if (self == nil) {
        return;
    }
    
    weakify(self);
    
    self.item = responseObject;
    
    // add Body
    [self addTitle];
    
    if (self.item.content.count > 20) {
        self->_deferredProcessing = YES;
    }
    
    if (self.item.coverImage) {
        Content *content = [Content new];
        content.type = @"image";
        content.url = self.item.coverImage;
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self addImage:content];
        });
    }
    
    if (self.item.enclosures && self.item.enclosures.count) {
        
        NSArray *const IMAGE_TYPES = @[@"image", @"image/jpeg", @"image/jpg", @"image/png", @"image/webp"];
        NSArray *const VIDEO_TYPES = @[@"video", @"video/h264", @"video/mp4", @"video/webm"];
        
        // check for images
        NSArray <Enclosure *> *enclosures = [self.item.enclosures rz_filter:^BOOL(Enclosure *obj, NSUInteger idx, NSArray *array) {
           
            return obj.type && [IMAGE_TYPES containsObject:obj.type];
            
        }];
        
        if (enclosures.count) {
            
            if (enclosures.count == 1) {
                Enclosure *enc = [enclosures firstObject];
                
                if (enc.url && enc.url.absoluteString) {
                    // single image, add as cover
                    Content *content = [Content new];
                    content.type = @"image";
                    content.url = [[[enclosures firstObject] url] absoluteString];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addImage:content];
                    });
                }
            }
            else {
                // Add as a gallery
                
                Content *content = [Content new];
                content.type = @"gallery";
                
                NSMutableArray *images = [NSMutableArray arrayWithCapacity:enclosures.count];
                
                for (Enclosure *enc in enclosures) {
                    
                    if (enc.url && enc.url.absoluteString) {
                        // single image, add as cover
                        Content *subcontent = [Content new];
                        subcontent.type = @"image";
                        subcontent.url = [[enc url] absoluteString];
                        
                        [images addObject:subcontent];
                    }
                    
                }
                
                content.items = images;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addGallery:content];
                });
                
            }
            
        }
        
        enclosures = [self.item.enclosures rz_filter:^BOOL(Enclosure *obj, NSUInteger idx, NSArray *array) {
           
            return obj.type && [VIDEO_TYPES containsObject:obj.type];
            
        }];
        
        if (enclosures.count) {
            
            for (Enclosure *enc in enclosures) { @autoreleasepool {
                
                if (enc.url && enc.url.absoluteString) {
                    // single image, add as cover
                    Content *subcontent = [Content new];
                    subcontent.type = @"video";
                    subcontent.url = [[enc url] absoluteString];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addVideo:subcontent];
                    });
                }
                
            } }
            
        }
        
    }
    
    [self.item.content enumerateObjectsUsingBlock:^(Content *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        strongify(self);
        
        /**
         * 1. Check the first item in the list
         * 2. If it's an image
         * 3. The article declares a cover image
         */
        if (idx == 0 && ([obj.type isEqualToString:@"img"] || [obj.type isEqualToString:@"image"]) && self.item.coverImage != nil) {
            // check if the cover image and the first image
            // are the same entities
            
            NSURLComponents *coverComponents = [NSURLComponents componentsWithString:self.item.coverImage];
            NSURLComponents *imageComponents = [NSURLComponents componentsWithString:obj.url];
            
            if ([coverComponents.path isEqualToString:imageComponents.path]) {
                return;
            }
        }
       
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            @autoreleasepool {
                [self processContent:obj];
            }
        });
        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        if (self == nil) {
            return;
        }
        
        self->_last = nil;
        
        DDLogInfo(@"Processing: %@", @([NSDate.date timeIntervalSinceDate:start]));
        
        if (self.item && self.item.isRead == NO) {
            // since v1.2, fetching the article marks it as read.
//            [MyFeedsManager article:self.item markAsRead:YES];
            
            if (self.providerDelegate && [self.providerDelegate respondsToSelector:@selector(userMarkedArticle:read:)]) {
                [self.providerDelegate userMarkedArticle:self.item read:YES];
            }
        }
        
        [self.stackView layoutIfNeeded];
        
        [self scrollViewDidScroll:self.scrollView];
        
        CGSize contentSize = self.scrollView.contentSize;
        contentSize.width = self.view.bounds.size.width;
        
        self.scrollView.contentSize = contentSize;
        
        DDLogDebug(@"ScrollView contentsize: %@", NSStringFromCGSize(contentSize));
        
        self.state = ArticleStateLoaded;
    });
    
    if (isChangingArticle && self.providerDelegate) {
        [(NSObject *)(self.providerDelegate) performSelectorOnMainThread:@selector(didChangeToArticle:) withObject:responseObject waitUntilDone:NO];
    }
}

#pragma mark - Drawing

- (void)addTitle {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        asyncMain(^{
            strongify(self);
            [self addTitle];
        });
        
        return;
    }
    
    if (self.item == nil) {
        return;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    NSString *author = nil;
    
    if (self.item.author) {
        if ([self.item.author isKindOfClass:NSString.class]) {
            author = self.item.author;
        }
        else {
            author = [self.item.author valueForKey:@"name"];
        }
    }
    else {
        author = @"Unknown";
    }
    
    author = [author stringByStrippingHTML];
    
    if ([author isBlank] == NO) {
        author = [author stringByAppendingString:@" • "];
    }
    
    Feed *feed = [MyFeedsManager feedForID:self.item.feedID];
    
    NSString *firstLine = formattedString(@"%@%@", feed != nil ? [feed.displayTitle stringByAppendingString:@"\n"] : @"", author);
    NSString *timestamp = [(NSDate *)(self.item.timestamp) timeAgoSinceDate:NSDate.date numericDates:YES numericTimes:YES];
    
    NSString *sublineText = formattedString(@"%@%@", firstLine, timestamp);
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

    para.paragraphSpacingBefore = 0.f;
    para.paragraphSpacing = 0.f;
    
    ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
    CGFloat baseFontSize = 32.f;
    
    if (self.item.articleTitle.length > 24) {
        baseFontSize = 26.f;
    }
    
    
    UIFont *baseFont = [fontPref isEqualToString:ALPSystem] ? [UIFont boldSystemFontOfSize:baseFontSize] : [UIFont fontWithName:[[[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString] stringByAppendingString:@"-Bold"] size:baseFontSize];
    
    UIFont * titleFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:baseFont];
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : titleFont,
                                     NSForegroundColorAttributeName: theme.titleColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: [NSNull null],
                                     };
    
    // Subline
    baseFontSize = 16.f;
    baseFont = [fontPref isEqualToString:ALPSystem] ? [UIFont systemFontOfSize:baseFontSize weight:UIFontWeightMedium] : [UIFont fontWithName:[[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString] size:baseFontSize];
    
    UIFont *subtextFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:baseFont];
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: subtextFont,
                                        NSForegroundColorAttributeName: theme.captionColor,
                                        NSParagraphStyleAttributeName: para,
                                        NSKernAttributeName: [fontPref isEqualToString:ALPSystem] ? @(-0.43f) : [NSNull null]
                                        };
    
    NSMutableAttributedString *subline = [[NSMutableAttributedString alloc] initWithString:sublineText attributes:subtextAttributes];
    NSRange feedTitleRange = NSMakeRange(NSNotFound, 0);
    
    if (feed) {
        feedTitleRange = [sublineText rangeOfString:feed.displayTitle];
    }
    
    if (feedTitleRange.location != NSNotFound) {
        [subline addAttribute:NSForegroundColorAttributeName value:theme.tintColor range:feedTitleRange];
    }
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:self.item.articleTitle attributes:baseAttributes];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    label.numberOfLines = 0;
    label.attributedText = attrs;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.lineBreakMode = NSLineBreakByWordWrapping;
//    label.preferredMaxLayoutWidth = self.view.bounds.size.width;
    
    [label sizeToFit];
    
    label.backgroundColor = theme.articleBackgroundColor;
    label.opaque = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *sublabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    sublabel.numberOfLines = 0;
    sublabel.attributedText = subline;
    sublabel.translatesAutoresizingMaskIntoConstraints = NO;
    sublabel.lineBreakMode = NSLineBreakByWordWrapping;
//    sublabel.preferredMaxLayoutWidth = self.view.bounds.size.width;
    
    [sublabel sizeToFit];
    
    sublabel.backgroundColor = theme.articleBackgroundColor;
    sublabel.opaque = YES;
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 48.f)];
    mainView.translatesAutoresizingMaskIntoConstraints = NO;
    [mainView addSubview:label];
    
    [label.leadingAnchor constraintEqualToAnchor:mainView.leadingAnchor constant:4.f].active = YES;
    [label.trailingAnchor constraintEqualToAnchor:mainView.trailingAnchor constant:4.f].active = YES;
    [label.topAnchor constraintEqualToAnchor:mainView.topAnchor].active = YES;
    [label setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
    [mainView addSubview:sublabel];
    
    [sublabel.leadingAnchor constraintEqualToAnchor:mainView.leadingAnchor constant:4.f].active = YES;
    [sublabel.trailingAnchor constraintEqualToAnchor:mainView.trailingAnchor constant:4.f].active = YES;
    [sublabel.firstBaselineAnchor constraintEqualToSystemSpacingBelowAnchor:label.lastBaselineAnchor multiplier:1.2f].active = YES;
    [sublabel setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
    [sublabel.bottomAnchor constraintEqualToAnchor:mainView.bottomAnchor].active = YES;
    
    if ([Paragraph languageDirectionForText:self.item.articleTitle] == NSLocaleLanguageDirectionRightToLeft) {
        mainView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        label.textAlignment = NSTextAlignmentRight;
        sublabel.textAlignment = NSTextAlignmentRight;
    }
    
    [mainView sizeToFit];
    
    [self.stackView addArrangedSubview:mainView];
    
}

#pragma mark -

- (BOOL)showImage {
    if ([SharedPrefs.imageLoading isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (BOOL)containsOnlyImages:(Content *)content {
    
    if ([content.type isEqualToString:@"container"] || [content.type isEqualToString:@"div"]) {
        
        BOOL contained = YES;
        
        for (Content *item in content.items) { @autoreleasepool {
            contained = contained && ([item.type isEqualToString:@"image"] || [item.type isEqualToString:@"img"]);
            if (contained == NO)
                break;
        } }
        
        return contained;
        
    }
    
    return NO;
}

- (void)processContent:(Content *)content {
    if ([content.type isEqualToString:@"container"] || [content.type isEqualToString:@"div"]) {
        if ([content.items count]) {
            
            if ([self containsOnlyImages:content]) {
                
                if ((!content.images || content.images.count == 0) && (content.items && content.items.count > 0)) {
                    content.images = content.items.copy;
                    content.items = nil;
                }
                
                content.type = @"gallery";
                
                [self addGallery:content];
                return;
            }
            
            NSUInteger idx = 0;
            
            for (Content *subcontent in [content items]) { @autoreleasepool {
                
                [self processContent:subcontent];
                
                idx++;
            }}
        }
    }
    else if ([content.type isEqualToString:@"paragraph"] || [content.type isEqualToString:@"cite"] || [content.type isEqualToString:@"span"]) {
        if (content.content.length)
            [self addParagraph:content caption:NO];
        else if (content.items) {
            for (Content *subcontent in content.items) {
                [self processContent:subcontent];
            }
        }
    }
    else if ([content.type isEqualToString:@"heading"]) {
        if (content.content.length)
            [self addHeading:content];
    }
    else if ([content.type isEqualToString:@"linebreak"]) {
        [self addLinebreak];
    }
    else if ([content.type isEqualToString:@"figure"] && content.items && content.items.count) {
        for (Content *image in content.items) {
            [self addImage:image];
        }
    }
    else if ([content.type isEqualToString:@"image"]) {
        [self addImage:content];
    }
    else if ([content.type isEqualToString:@"blockquote"]) {
        [self addQuote:content];
    }
    else if ([content.type isEqualToString:@"list"] || [content.type containsString:@"list"]) {
        [self addList:content];
    }
    else if ([content.type isEqualToString:@"anchor"]) {
        [self addParagraph:content caption:NO];
    }
    else if ([content.type isEqualToString:@"aside"]) {
            [self addAside:content];
    }
    else if ([content.type isEqualToString:@"youtube"]) {
        [self addYoutube:content];
        [self addLinebreak];
    }
    else if ([content.type isEqualToString:@"gallery"]) {
        [self addGallery:content];
    }
    else if (([content.type isEqualToString:@"a"] || [content.type isEqualToString:@"anchor"])
             || ([content.type isEqualToString:@"b"] || [content.type isEqualToString:@"strong"])
             || ([content.type isEqualToString:@"i"] || [content.type isEqualToString:@"em"])
             || ([content.type isEqualToString:@"sup"] || [content.type isEqualToString:@"sub"])) {
        
        if (content.content && content.content.length) {
            [self addParagraph:content caption:NO];
        }
        else if (content.items) {
            // if it's a linked image
            if (content.items.count == 1) {
                Content *item = content.items[0];
                if ([item.type isEqualToString:@"image"]) {
                    [self addImage:item link:content.url];
                }
                else {
                    [self processContent:item];
                }
            }
            else {
                for (Content *sub in content.items) { @autoreleasepool {
                    
                    [self processContent:sub];
                    
                } }
            }
        }
        
    }
    else if ([content.type isEqualToString:@"pre"]) {
        [self addPre:content];
    }
    else if ([content.type isEqualToString:@"li"]) {
        Content *parent = [Content new];
        parent.type = @"orderedlist";
        parent.items = @[content];
        
        [self addList:parent];
    }
    else if ([content.type isEqualToString:@"tweet"]) {
        [self addTweet:content];
    }
    else if ([content.type isEqualToString:@"br"]) {
        [self addLinebreak];
    }
    else if ([content.type isEqualToString:@"hr"]) {
        
    }
    else if ([content.type isEqualToString:@"script"]) {
        // wont be handled at the moment
    }
    else if ([content.type isEqualToString:@"video"]) {
        [self addVideo:content];
    }
    else {
        DDLogWarn(@"Unhandled node: %@", content);
    }
}

- (void)addParagraph:(Content *)content caption:(BOOL)caption {
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, LayoutPadding * 2);
    
    Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
#if DEBUG_LAYOUT == 1
    para.backgroundColor = UIColor.blueColor;
#endif
    
    para.avoidsLazyLoading = !_deferredProcessing;
    
    if ([_last isMemberOfClass:Heading.class])
        para.afterHeading = YES;
    
    if ([_last isMemberOfClass:Paragraph.class]
        && !caption) {
        // check if we have a duplicate
        Paragraph *lastPara = (Paragraph *)_last;
        if(lastPara.isCaption && ([lastPara.text isEqualToString:content.content] || [lastPara.attributedText.string isEqualToString:content.content]))
            return;
    }
    
    para.caption = caption;
    
    BOOL rangeAdded = NO;
    
    // check if attributes has href
    if (![content.type isEqualToString:@"paragraph"]) {
        if (content.attributes && [content.attributes valueForKey:@"href"]) {
            NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
            
            Range *newRange = [Range new];
            newRange.element = @"anchor";
            newRange.range = NSMakeRange(0, content.content.length);
            newRange.url = [content.attributes valueForKey:@"href"];
            
            [ranges addObject:newRange];
            
            content.ranges = ranges.copy;
            rangeAdded = YES;
        }
        else if (content.url) {
            NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
            
            Range *newRange = [Range new];
            newRange.element = @"anchor";
            newRange.range = NSMakeRange(0, content.content.length);
            newRange.url = content.url;
            
            [ranges addObject:newRange];
            
            content.ranges = ranges.copy;
            rangeAdded = YES;
        }
        else {
            NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
            
            Range *newRange = [Range new];
            newRange.element = content.type;
            newRange.range = NSMakeRange(0, content.content.length);
            
            [ranges addObject:newRange];
            
            content.ranges = ranges.copy;
            rangeAdded = YES;
        }
    }
    
    // prevents the period from overflowing to the next line.
    if (content.content) {
        NSString *ctx = [content content];
        
        if ([ctx isEqualToString:@"."] || [ctx isEqualToString:@","])
            rangeAdded = YES;
        else if (ctx.length && ([[ctx substringToIndex:1] isEqualToString:@"."] || [[ctx substringToIndex:1] isEqualToString:@","] || [[ctx substringToIndex:1] isEqualToString:@" "]))
            rangeAdded = YES;
        else if ([[ctx stringByStrippingWhitespace] length] < 6) {
            rangeAdded = YES;
        }
        else if ([[[ctx stringByStrippingWhitespace] componentsSeparatedByString:@" "] count] == 1) {
            rangeAdded = YES;
        }
    }
    
    if ([_last isMemberOfClass:Paragraph.class] && ![(Paragraph *)_last isCaption] && !para.isCaption) {
        
        para = nil;
        
        // since the last one is a paragraph as well, simlpy append to it.
        Paragraph *last = (Paragraph *)_last;
        
        NSMutableAttributedString *attrs = last.attributedText.mutableCopy;
        
        NSAttributedString *newAttrs = [last processText:content.content ranges:content.ranges attributes:content.attributes];
        
        if (newAttrs) {
            NSAttributedString *accessory = [[NSAttributedString alloc] initWithString:formattedString(@"%@", rangeAdded ? @" " : @"\n\n")];
            
            [attrs appendAttributedString:accessory];
            [attrs appendAttributedString:newAttrs];
            
            if (!rangeAdded) {
                last.bigContainer = YES;
            }
            
            last.attributedText = attrs.copy;
        }
        
        attrs = nil;
        newAttrs = nil;
        return;
    }
    
    [para setText:content.content ranges:content.ranges attributes:content.attributes];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    [self.stackView addArrangedSubview:para];
    
    if (caption) {
        
        if ([_last isKindOfClass:Linebreak.class]) {
            NSUInteger index = [[self.stackView arrangedSubviews] indexOfObject:_last];
            index--;
            
            [self.stackView removeArrangedSubview:_last];
            [_last removeFromSuperview];
            
            _last = [[self.stackView arrangedSubviews] objectAtIndex:index];
        }
        
        // reduce the spacing to the previous element
        [self.stackView setCustomSpacing:0 afterView:_last];
    }
    
    _last = para;
    
    para.delegate = self;
}

- (void)addHeading:(Content *)content {
    
    if (_last && [_last isMemberOfClass:Paragraph.class]) {
        [self addLinebreak];
    }
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 0);
    
    Heading *heading = [[Heading alloc] initWithFrame:frame];
    heading.delegate = self;
#ifdef DEBUG_LAYOUT
#if DEBUG_LAYOUT == 1
    heading.backgroundColor = UIColor.redColor;
#endif
#endif
    heading.level = content.level.integerValue;
    
    [heading setText:content.content ranges:content.ranges attributes:content.attributes];
    
    if (content.identifier && ![content.identifier isBlank]) {
        
        // content identifiers should only be URL safe chars
        NSString *identifier = [content.identifier stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        
        heading.identifier = content.identifier;
        
        NSAttributedString *attrs = heading.attributedText;
        
        NSURL *url = formattedURL(@"%@#%@", self.item.articleURL, identifier);
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:MAX(14.f, heading.bodyFont.pointSize - 8.f)],
                                     NSLinkAttributeName: url
                                     };
        
        NSMutableAttributedString *prefix = [[NSAttributedString alloc] initWithString:@"🔗 " attributes:attributes].mutableCopy;
        
        [prefix appendAttributedString:attrs];
        heading.attributedText = prefix;
        heading.delegate = self;
    }
    
    frame.size.height = heading.intrinsicContentSize.height;
    heading.frame = frame;
    
    _last = heading;
    
    [self.stackView addArrangedSubview:heading];
}

- (void)addLinebreak {
    // this rejects multiple \n in succession which may be undesired.
    if (_last && [_last isMemberOfClass:Linebreak.class])
        return;
    
    // append to the para if one is available
    if (_last && ([_last isMemberOfClass:Paragraph.class] || [_last isMemberOfClass:Heading.class])) {
        Paragraph *para = (Paragraph *)_last;
        
        NSString *string = [para attributedText].string;
        NSRange range = [string rangeOfString:@"\n"];
        if (range.location != NSNotFound && (range.location == (string.length - 1))) {
            // the linebreak is the last char.
            return;
        }
    }
    
    CGFloat height = 24.f;
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        height = 12.f;
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, height);
    
    Linebreak *linebreak = [[Linebreak alloc] initWithFrame:frame];
#ifdef DEBUG_LAYOUT
#if DEBUG_LAYOUT == 1
    linebreak.backgroundColor = UIColor.greenColor;
#endif
#endif
    
    [self.stackView addArrangedSubview:linebreak];
    [self.stackView setCustomSpacing:0.f afterView:_last];

    _last = linebreak;
    
    [self.stackView setCustomSpacing:0.f afterView:_last];
}

- (void)addImage:(Content *)content {
    [self addImage:content link:nil];
}

- (void)addImage:(Content *)content link:(NSString *)link {
    
    if (![self showImage])
        return;
    
    // ignores tracking images
    if (content && CGSizeEqualToSize(content.size, CGSizeZero) == NO && content.size.width == 1.f && content.size.height == 1.f) {
        return;
    }
    
    if ([_last isMemberOfClass:Heading.class] || !_last || [_last isMemberOfClass:Paragraph.class])
        [self addLinebreak];
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    
    if ([content valueForKey:@"size"] && CGSizeEqualToSize(content.size, CGSizeZero) == NO) {
        frame.size = content.size;
    }
    
    CGFloat scale = content.size.height / content.size.width;
    
    Image *imageView = [[Image alloc] initWithFrame:frame];
    
    if (link && [link isKindOfClass:NSArray.class]) {
        link = [(NSArray *)link rz_reduce:^id(id prev, id current, NSUInteger idx, NSArray *array) {
            if (!prev && [current isBlank] == NO) {
                return current;
            }
            
            return prev;
        }];
    }
    
    // make the imageView tappable
    if (link != nil && [link isBlank] == NO) {
        imageView.link = [NSURL URLWithString:link];
    }
    
    _last = imageView;
    
    [self.stackView addArrangedSubview:imageView];
    
    if (!CGSizeEqualToSize(content.size, CGSizeZero) && scale != NAN) {
        frame.size.width = content.size.width;
        frame.size.height = frame.size.width * scale;
        imageView.frame = frame;
        
        if (content.size.width > content.size.height) {
            imageView.aspectRatio = [imageView.heightAnchor constraintEqualToAnchor:imageView.widthAnchor multiplier:scale];
        }
        else {
            imageView.aspectRatio = [imageView.widthAnchor constraintEqualToAnchor:imageView.heightAnchor multiplier:scale];
        }
        
        imageView.aspectRatio.priority = 999;
        imageView.aspectRatio.active = YES;
    }
    else {
        imageView.aspectRatio = [imageView.heightAnchor constraintEqualToConstant:32.f];
        imageView.aspectRatio.priority = 999;
        imageView.aspectRatio.active = YES;
    }
    
    [self.images addPointer:(__bridge void *)imageView];
    imageView.idx = self.images.count - 1;
    
    NSString *url = [content urlCompliantWithUsersPreferenceForWidth:self.scrollView.bounds.size.width];
    
    if ([url containsString:@"feedburner.com"] && [([url pathExtension] ?: @"") isBlank]) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnImageWithURL:)];
        imageView.userInteractionEnabled = YES;
        
        [imageView addGestureRecognizer:tap];
    }
    
    imageView.URL = [NSURL URLWithString:url];
    
    [self addLinebreak];
    
    if ((content.alt && ![content.alt isBlank]) || (content.attributes && ![([content.attributes valueForKey:@"alt"] ?: @"") isBlank])) {
        
        imageView.accessibilityLabel = @"Image";
        imageView.accessibilityValue = content.alt ?: [content.attributes valueForKey:@"alt"];
        imageView.accessibilityHint = imageView.accessibilityValue;
        imageView.isAccessibilityElement = YES;
        
        Content *caption = [Content new];
        caption.content = imageView.accessibilityValue;
        caption.isAccessibilityElement = NO; // the image itself presents the caption.
        [self addParagraph:caption caption:YES];
    }

}

- (void)addGallery:(Content *)content {
    
    if (![self showImage])
        return;
    
    if (_last && ![_last isKindOfClass:Linebreak.class]) {
        [self addLinebreak];
    }
    
    Gallery *gallery = [[Gallery alloc] initWithNib];
    gallery.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200.f);
    gallery.maxScreenHeight = self.view.bounds.size.height - (self.view.safeAreaInsets.top + self.additionalSafeAreaInsets.bottom) - 12.f - 38.f;
    
    [self.stackView addArrangedSubview:gallery];
    // set images after adding it to the superview since -[Gallery setImages:] triggers layout.
    gallery.images = content.images;
    
    [self.images addPointer:(__bridge void *)gallery];
    gallery.idx = self.images.count - 1;
    
}

- (void)addQuote:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width - 48.f, 32.f);
    
    if (!content.content && (!content.items || content.items.count == 0))
        return;
    
    Blockquote *para = [[Blockquote alloc] initWithFrame:frame];
    para.avoidsLazyLoading = !_deferredProcessing;
    
    if (content.content) {
        [para setText:content.content ranges:content.ranges attributes:content.attributes];
    }
    else if (content.items && content.items.count > 0) {
        
        NSMutableAttributedString *mattrs = [NSMutableAttributedString new];
        
        for (Content *item in content.items) { @autoreleasepool {
            
            // remove "\n" from the item's content
            // daringfireball adds linebreaks manually to it's blockquotes
            
            if (item.content != nil && [item.content isBlank] == NO) {
                item.content = [item.content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            }
            
            NSAttributedString *attrs = [para processText:item.content ranges:item.ranges attributes:item.attributes];
            
            if ([item.type isEqualToString:@"ol"] || [item.type isEqualToString:@"ul"] || [item.type containsString:@"ordered"]) {
                List *list = [List new];
                attrs = [list processContent:item];
                
                list = nil;
            }
            
            BOOL rangeAdded = NO;
            
            // check if attributes has href
            if (![content.type isEqualToString:@"paragraph"]) {
                if (content.attributes && [content.attributes valueForKey:@"href"]) {
                    NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
                    
                    Range *newRange = [Range new];
                    newRange.element = @"anchor";
                    newRange.range = NSMakeRange(0, content.content.length);
                    newRange.url = [content.attributes valueForKey:@"href"];
                    
                    [ranges addObject:newRange];
                    
                    content.ranges = ranges.copy;
                    rangeAdded = YES;
                }
                else if (content.url) {
                    NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
                    
                    Range *newRange = [Range new];
                    newRange.element = @"anchor";
                    newRange.range = NSMakeRange(0, content.content.length);
                    newRange.url = content.url;
                    
                    [ranges addObject:newRange];
                    
                    content.ranges = ranges.copy;
                    rangeAdded = YES;
                }
                // this is not applicable for blockquotes
                // as it adds a quote range to the blockquote
//                else {
//                    NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
//
//                    Range *newRange = [Range new];
//                    newRange.element = content.type;
//                    newRange.range = NSMakeRange(0, content.content.length);
//
//                    [ranges addObject:newRange];
//
//                    content.ranges = ranges.copy;
//                    rangeAdded = YES;
//                }
            }
            
            // prevents the period from overflowing to the next line.
            if (content.content) {
                NSString *ctx = [content content];
                
                if ([ctx isEqualToString:@"."] || [ctx isEqualToString:@","])
                    rangeAdded = YES;
                else if (ctx.length && ([[ctx substringToIndex:1] isEqualToString:@"."] || [[ctx substringToIndex:1] isEqualToString:@","] || [[ctx substringToIndex:1] isEqualToString:@" "]))
                    rangeAdded = YES;
                else if ([[ctx stringByStrippingWhitespace] length] < 6) {
                    rangeAdded = YES;
                }
                else if ([[[ctx stringByStrippingWhitespace] componentsSeparatedByString:@" "] count] == 1) {
                    rangeAdded = YES;
                }
            }
            
            [mattrs appendAttributedString:attrs];
            [mattrs appendAttributedString:[[NSAttributedString alloc] initWithString:rangeAdded ? @" " : @"\n\n"]];
        } }
        
        para.attributedText = mattrs.copy;
//        [para performSelectorOnMainThread:NSSelectorFromString(@"updateFrame") withObject:nil waitUntilDone:YES];
        
    }
    else {
        
    }
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
#if DEBUG_LAYOUT == 1
    para.backgroundColor = UIColor.orangeColor;
#endif
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
    
//    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
}

- (void)addList:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    
    List *list = [[List alloc] initWithFrame:frame];
    list.avoidsLazyLoading = !_deferredProcessing;
    [list setContent:content];
    
    frame.size.height = list.intrinsicContentSize.height;
    list.frame = frame;
    
    _last = list;
    
    list.delegate = self;
    
    [self.stackView addArrangedSubview:list];
//    [list.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding].active = YES;
    
}

- (void)addAside:(Content *)content
{
    if (content.items && content.items.count) {
        for (Content *item in content.items) { @autoreleasepool {
            [self processContent:item];
        } }
        return;
    }
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 0);
    
    Aside *para = [[Aside alloc] initWithFrame:frame];
    
    if ([_last isMemberOfClass:Heading.class])
        para.afterHeading = YES;
    
    [para setText:content.content ranges:content.ranges attributes:content.attributes];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
    
//    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
}

- (void)addYoutube:(Content *)content {
    
    if (![self showImage])
        return;
    
    NSString *videoID = [[content url] lastPathComponent];
    
    DDLogDebug(@"Extracting YT info for: %@", videoID);
    
    if ([_last isKindOfClass:Linebreak.class] == NO) {
        [self addLinebreak];
    }
    
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    playerController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerController.updatesNowPlayingInfoCenter = NO;
    
    [self addChildViewController:playerController];
    
    UIView *playerView = playerController.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [playerView.heightAnchor constraintEqualToAnchor:playerView.widthAnchor multiplier:(9.f/16.f)].active = YES;
    
    [self.stackView addArrangedSubview:playerView];
    [playerController didMoveToParentViewController:self];
    
    [self.videos addPointer:(__bridge void *)playerController];
    
    _last = playerView;
    
    [self addLinebreak];
    
    [self.ytExtractor extract:videoID success:^(VideoInfo * _Nonnull videoInfo) {
        
        if (videoInfo) {
            YTPlayer *player = [YTPlayer playerWithURL:videoInfo.url];
            playerController.player = player;
            
            player.playerViewController = playerController;
            
            if (videoInfo.coverImage) {

                UIImageView *imageView = [[UIImageView alloc] initWithFrame:playerController.contentOverlayView.bounds];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.autoUpdateFrameOrConstraints = NO;

                [playerController.contentOverlayView addSubview:imageView];

                [imageView.widthAnchor constraintEqualToAnchor:playerController.contentOverlayView.widthAnchor multiplier:1.f].active = YES;
                [imageView.heightAnchor constraintEqualToAnchor:playerController.contentOverlayView.heightAnchor multiplier:1.f].active = YES;
                [imageView.leadingAnchor constraintEqualToAnchor:playerController.contentOverlayView.leadingAnchor].active = YES;
                [imageView.trailingAnchor constraintEqualToAnchor:playerController.contentOverlayView.trailingAnchor].active = YES;

                NSString *thumbnail = [videoInfo.coverImage pathForImageProxy:NO maxWidth:0.f quality:0.f];

                [imageView il_setImageWithURL:thumbnail success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {

//                    [playerController.player addObserver:self forKeyPath:propSel(rate) options:NSKeyValueObservingOptionNew context:KVO_PlayerRate];
                    
                    DDLogInfo(@"Video player image has been set: %@", URL);
                    
                } error:^(NSError * _Nonnull error) {

                    DDLogError(@"Video player failed to set image: %@\nError:%@", videoInfo.coverImage, error.localizedDescription);

                }];

            }
            
        }
        else {
            [self.stackView removeArrangedSubview:playerView];
            [playerView removeFromSuperview];
            
            [self _addYoutube:content];
        }
        
    } error:^(NSError * _Nonnull error) {
       
        DDLogError(@"Error extracting Youtube Video info: %@", error.localizedDescription);
        
        [self.stackView removeArrangedSubview:playerView];
        [playerView removeFromSuperview];
        
        [self _addYoutube:content];
        
    }];
}

// fallback
- (void)_addYoutube:(Content *)content {
    // this now breaks the layout which is not desirable.
//    return;
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 0);
    Youtube *youtube = [[Youtube alloc] initWithFrame:frame];
    youtube.URL = [NSURL URLWithString:content.url];
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
    
//    [youtube.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:LayoutPadding].active = YES;
    
    [self addLinebreak];
}

- (void)addPre:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    Code *code = [[Code alloc] initWithFrame:frame];
    
    if (content.content) {
        code.attributedText = [CodeParser.sharedCodeParser parse:content.content];
    }
    else {
        for (Content *item in content.items) { @autoreleasepool {
            [self processContent:item];
        } }
    }
    
    [self.stackView addArrangedSubview:code];
    
}

- (void)addTweet:(Content *)content {
    CGRect frame = CGRectMake(0, 0, MIN(self.stackView.bounds.size.width, 480.f), 0);
    Tweet *tweet = [[Tweet alloc] initWithNib];
    tweet.frame = frame;
    
    tweet.textview.delegate = self;
    
    [tweet configureContent:content];
    
    _last = tweet;
    
    [self.stackView addArrangedSubview:tweet];
    
//    [tweet.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

- (void)addAudio:(Content *)content {
    
}

- (void)addVideo:(Content *)content {
    
    if (content.url == nil && content.content == nil)
        return;
    
    if ([_last isKindOfClass:Linebreak.class] == NO) {
        [self addLinebreak];
    }
    
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    playerController.player = [AVPlayer playerWithURL:[NSURL URLWithString:(content.url ?: content.content)]];
    playerController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self addChildViewController:playerController];
    
    UIView *playerView = playerController.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [playerView.heightAnchor constraintEqualToAnchor:playerView.widthAnchor multiplier:(9.f/16.f)].active = YES;
    
    [self.stackView addArrangedSubview:playerView];
    [playerController didMoveToParentViewController:self];
    
    [self.videos addPointer:(__bridge void *)playerController];
    
    _last = playerView;
    
    [self addLinebreak];
}

#pragma mark - Actions

- (void)didTapOnImageWithURL:(UITapGestureRecognizer *)sender {
    
    Image *view = (Image *)[sender view];
    NSString *url = [[view URL] absoluteString];
    
    NSURL *formatted = formattedURL(@"yeti://external?link=%@", url);
    
    [UIApplication.sharedApplication openURL:formatted options:@{} completionHandler:nil];
    
}

#pragma mark - <UIScrollViewDelegate>

- (NSArray <UIView *> *)visibleViews {
    
    if (self.stackView == nil || self.stackView.arrangedSubviews.count == 0) {
        return @[];
    }
    
    UIScrollView *scrollView = self.scrollView;
    
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    
    return [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return CGRectIntersectsRect(visibleRect, CGRectOffset(obj.frame, 0, 48.f));
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    if (scrollView != self.stackView.superview)
        return;
    
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    
    if (_deferredProcessing) {
        NSArray <UIView *>  * visibleViews = [self visibleViews];
        
        // make these views visible
        for (UIView *subview in visibleViews) { @autoreleasepool {
            if ([subview isKindOfClass:Paragraph.class] && ![(Paragraph *)subview isAppearing]) {
                [(Paragraph *)subview viewWillAppear];
            }
        } }
        
        // tell these views to hide their content
        NSArray <UIView *> *scrolledOutViews = [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
            return [obj respondsToSelector:@selector(isAppearing)] && !CGRectIntersectsRect(visibleRect, CGRectOffset(obj.frame, 0, 48.f));
        }];
        
        for (UIView *subview in scrolledOutViews) {
            if ([subview isKindOfClass:Paragraph.class] && [(Paragraph *)subview isAppearing]) {
                [(Paragraph *)subview viewDidDisappear];
            }
        }
    }
    else {
        // for lazy-loading, the viewDidDisappear method of Paragraph nils out accesssibilityElements
        NSArray <UIView *> *visibleViews = [self visibleViews];
        
        NSArray <Paragraph *> *paragraphs = (NSArray <Paragraph *> *)[visibleViews rz_filter:^BOOL(UIView *obj, NSUInteger idx, NSArray *array) {
            return [obj isKindOfClass:Paragraph.class];
        }];
        
        // we only need paragraphs that assign custom UIAccessibilityElements
        NSArray <Paragraph *> *overridingParagraphs = (NSArray <Paragraph *> *)[paragraphs rz_filter:^BOOL(Paragraph *obj, NSUInteger idx, NSArray *array) {
            return obj.isCaption == NO && [obj isAccessibilityElement] == NO;
        }];
        
        for (Paragraph *obj in overridingParagraphs) {
            // force these to be recalculated
            obj.accessibileElements = nil;
        }
    }
    
//    CGPoint point = scrollView.contentOffset;
//    // adding the scrollView's height here triggers loading of the image as soon as it's about to appear on screen.
//    point.y += scrollView.bounds.size.height;
    
    for (Image *imageview in self.images) { @autoreleasepool {
        
        BOOL contains = CGRectContainsRect(visibleRect, imageview.frame) || CGRectIntersectsRect(visibleRect, imageview.frame);
        // the first image may be out of bounds of the scrollView when it's loaded.
        // check if it's frame is contained within the frame of the scrollView.
        if (imageview.idx == 0) {
            CGRect imageFrame = imageview.frame;
            imageFrame.origin.x = 0.f;
            contains = contains || CGRectContainsRect(visibleRect, imageFrame);
        }
        
//        DDLogDebug(@"Frame:%@, contains: %@", NSStringFromCGRect(imageview.frame), @(contains));
        
        if ([imageview isMemberOfClass:Gallery.class]) {
            [(Gallery *)imageview setLoading:YES];
        }
        else if (!imageview.imageView.image && contains && !imageview.isLoading) {
//            DDLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageview.loading = YES;
                if (imageview.URL && ![imageview.URL.absoluteString isBlank]) {
                    [imageview il_setImageWithURL:imageview.URL];
                }
            });
        }
        else if (imageview.imageView.image && !contains) {
            
            if (imageview.isLoading) {
                [imageview il_cancelImageLoading];
                imageview.loading = NO;
            }
            
            if ([imageview isAnimatable] && imageview.isAnimating) {
                [imageview didTapStartStop:imageview.startStopButton];
            }
            else {
                // remove the image from the buffer so we release the RAM occupied by it
                if (imageview.imageView.image != nil) {
                    imageview.imageView.image = nil;
                }
                
            }
        }
    } }
    
    CGFloat y = scrollView.contentOffset.y;
    
    BOOL enableTop = y > (scrollView.bounds.size.height / 2.f);
    if (enableTop != _helperView.startOfArticle.isEnabled)
        _helperView.startOfArticle.enabled = enableTop;
    
    BOOL enableBottom = y < (scrollView.contentSize.height - scrollView.bounds.size.height);
    if (enableBottom != _helperView.endOfArticle.isEnabled)
        _helperView.endOfArticle.enabled = enableBottom;
}

#pragma mark - <UITextViewDelegate>

- (void)scrollToIdentifer:(NSString *)identifier {
    
    if (!identifier || [identifier isBlank])
        return;
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(scrollToIdentifer:) withObject:identifier waitUntilDone:NO];
        return;
    }
    
    identifier = [identifier stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    DDLogDebug(@"Looking up anchor %@", identifier);
    
    NSArray <Paragraph *> *paragraphs = [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return [obj isKindOfClass:Paragraph.class];
    }];
    
    __block Paragraph *required = nil;
    
    for (Paragraph *para in paragraphs) { @autoreleasepool {
        NSAttributedString *attrs = para.attributedText;
        
        [attrs enumerateAttribute:NSLinkAttributeName inRange:NSMakeRange(0, attrs.length) options:NSAttributedStringEnumerationReverse usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            if (value) {
                NSString *compare = value;
                if ([value isKindOfClass:NSURL.class]) {
                    compare = [(NSURL *)value absoluteString];
                }
                
                compare = [compare stringByReplacingOccurrencesOfString:@"#" withString:@""];
                
                float ld = [identifier compareStringWithString:compare];
                DDLogDebug(@"href:%@ distance:%@", compare, @(ld));
                
                BOOL contained = [compare containsString:identifier] || [identifier containsString:compare];
                
                DDLogDebug(@"sub matching:%@", contained ? @"Yes" : @"No");
                
                // also check last N chars
                
                // the comparison is not done against 0
                // to avoid comparing to self
                if (((ld > 1 && ld <= 3) && !contained) || ((ld >= 2 && ld <= 5) && contained)) {
                    required = para;
                    *stop = YES;
                }
            }
        }];
        
        if (required)
            break;
    } }
    
    paragraphs = nil;
    
    if (required) {
        CGRect frame = required.frame;
        
//        DDLogDebug(@"Found the paragraph: %@", required);
        
        self.scrollView.userInteractionEnabled = NO;
        // compare against the maximum contentOffset which is contentsize.height - bounds.size.height
        CGFloat yOffset = MIN(frame.origin.y - 160, (self.scrollView.contentSize.height - self.scrollView.bounds.size.height));
        
        // if we're scrolling down, add the bottom offset so the bottom bar does not interfere
        if (yOffset > self.scrollView.contentOffset.y)
            yOffset += self.scrollView.adjustedContentInset.bottom;
        else
            yOffset -= self.scrollView.adjustedContentInset.top;
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
            self.scrollView.userInteractionEnabled = NO;
        });
        
        weakify(required);
        
        // animate background on paragraph
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        strongify(required);
        
        required.layer.cornerRadius = 4.f;
        
        NSTimeInterval animationDuration = 0.3;
        
        [UIView animateWithDuration:animationDuration delay:1 options:kNilOptions animations:^{
            
            required.backgroundColor = theme.focusColor;
            
            strongify(self);
            self.scrollView.userInteractionEnabled = YES;
            
        } completion:^(BOOL finished) { dispatch_async(dispatch_get_main_queue(), ^{
            
            if (finished) {
                [UIView animateWithDuration:animationDuration delay:1.5 options:kNilOptions animations:^{
                    
                    required.backgroundColor = theme.articleBackgroundColor;
                    
                } completion:^(BOOL finished) {
                    required.layer.cornerRadius = 0.f;
                }];
            }
            
        }); }];
    }
    else {
        // try and see if a heading is idefinited
        [self scrollToHeading:identifier];
    }
    
}

- (BOOL)scrollToHeading:(NSString *)identifier {
    
    identifier = [identifier stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    NSArray <Heading *> *headings = [[self.stackView arrangedSubviews] rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return ([obj isKindOfClass:Heading.class]);
    }];
    
    Heading *theChosenOne = [headings rz_reduce:^id(Heading *prev, Heading *current, NSUInteger idx, NSArray *array) {
        if (current.identifier && [current.identifier isEqualToString:identifier])
            return current;
        return prev;
    }];
    
    if (!theChosenOne)
        return YES;
    
    CGRect frame = theChosenOne.frame;
    
    self.scrollView.userInteractionEnabled = NO;
    // compare against the maximum contentOffset which is contentsize.height - bounds.size.height
    CGFloat yOffset = MIN(frame.origin.y - 160, (self.scrollView.contentSize.height - self.scrollView.bounds.size.height));
    
    // if we're scrolling down, add the bottom offset so the bottom bar does not interfere
    if (yOffset > self.scrollView.contentOffset.y)
        yOffset += self.scrollView.adjustedContentInset.bottom;
    else
        yOffset -= self.scrollView.adjustedContentInset.top;
    
    yOffset += (self.scrollView.bounds.size.height / 2.f);
    
    [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
    
    weakify(self);
    
    asyncMain(^{
        strongify(self);
        self.scrollView.userInteractionEnabled = YES;
    });
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (URL.host == nil) {
        // absolute link in the article. Resovle to fully qualified URL
        NSURLComponents *articleComp = [NSURLComponents componentsWithString:[self.item articleURL]];
        NSURLComponents *urlComp = [NSURLComponents componentsWithString:URL.absoluteString];
        
        urlComp.host = articleComp.host;
        urlComp.scheme = articleComp.scheme;
        URL = [urlComp URL];
    }
    
    NSString *absolute = URL.absoluteString;
    
    if (interaction != UITextItemInteractionPresentActions) {
        // footlinks and the like
        if (absolute.length && [[absolute substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
            [self scrollToIdentifer:absolute];
            return NO;
        }
        
        // links to sections within the article
        if ([absolute containsString:self.item.articleURL] && ![absolute isEqualToString:self.item.articleURL]) {
            // get the section ID
            NSRange range = [absolute rangeOfString:@"#"];
            
            NSString *identifier = [absolute substringFromIndex:range.location];
            
            BOOL retval = [self scrollToHeading:identifier];
            
            if (!retval)
                return retval;
        }
    }
    
    if (interaction == UITextItemInteractionPreview)
        return YES;
    
    if (interaction == UITextItemInteractionPresentActions) {
        NSString * const linkedHeader = @"🔗 ";
        
        NSString *text = [textView.attributedText.string substringWithRange:characterRange];
        
        if ([text isEqualToString:linkedHeader]) {
            text = [[textView text] stringByReplacingOccurrencesOfString:linkedHeader withString:@""];
            
            NSString *articleTitle = (self.item.articleTitle && ![self.item.articleTitle isBlank]) ? formattedString(@"- %@", self.item.articleTitle) : @"";
            text = formattedString(@"%@%@", text, articleTitle);
        }
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[text, URL] applicationActivities:nil];
        
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            
            UIPopoverPresentationController *pvc = [avc popoverPresentationController];
            pvc.sourceView = textView;
            pvc.sourceRect = [Paragraph boundingRectIn:textView forCharacterRange:characterRange];
            
            DDLogDebug(@"view: %@", pvc.sourceView);
        }
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    else {
        NSURL *formatted = formattedURL(@"yeti://external?link=%@", absolute);
        
        [[UIApplication sharedApplication] openURL:formatted options:@{} completionHandler:nil];
    }
    
    return NO;
}

- (CGRect)boundingRectIn:(UITextView *)textview forCharacterRange:(NSRange)range
{
    NSTextStorage *textStorage = [textview textStorage];
    NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
    NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];
    
    NSRange glyphRange;
    
    // Convert the range for glyphs.
    [layoutManager characterRangeForGlyphRange:range actualGlyphRange:&glyphRange];
    
    return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}

#pragma mark - Getters

- (UINotificationFeedbackGenerator *)notificationGenerator {
    if (!_notificationGenerator) {
        _notificationGenerator = [[UINotificationFeedbackGenerator alloc] init];
        [_notificationGenerator prepare];
    }
    
    return _notificationGenerator;
}

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
}

- (UIView *)inputAccessoryView
{
    if (_showSearchBar == YES) {
        return self.searchView;
    }
    return nil;
}

- (UIInputView *)searchView
{
    if (!_searchView) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        CGRect frame = CGRectMake(0, 0, self.splitViewController.view.bounds.size.width, 52.f);
        
        UIInputView * searchView = [[UIInputView alloc] initWithFrame:frame];
        [searchView setValue:@(UIInputViewStyleKeyboard) forKeyPath:@"inputViewStyle"];
        searchView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        CGFloat borderHeight = 1/[[UIScreen mainScreen] scale];
        UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, borderHeight)];
        border.backgroundColor = theme.borderColor;
        border.translatesAutoresizingMaskIntoConstraints = NO;
        [border.heightAnchor constraintEqualToConstant:borderHeight].active = YES;
        
        [searchView addSubview:border];
        [border.topAnchor constraintEqualToAnchor:searchView.topAnchor].active = YES;
        [border.heightAnchor constraintEqualToAnchor:searchView.heightAnchor].active = YES;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(64.f, 8.f, frame.size.width - 64.f - 56.f , frame.size.height - 16.f)];
        searchBar.placeholder = @"Search Article";
        searchBar.keyboardType = UIKeyboardTypeDefault;
        searchBar.returnKeyType = UIReturnKeySearch;
        searchBar.delegate = self;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UITextField *searchField = [searchBar valueForKeyPath:@"searchField"];
        if (searchField) {
            searchField.textColor = theme.titleColor;
        }
        
        searchBar.backgroundColor = UIColor.clearColor;
        searchBar.backgroundImage = nil;
        searchBar.scopeBarBackgroundImage = nil;
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.translucent = NO;
        searchBar.accessibilityHint = @"Search for keywords in the article";
        
        [searchView addSubview:searchBar];
        self.searchBar = searchBar;
        
        [searchBar.heightAnchor constraintEqualToConstant:36.f].active = YES;
        
        UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
        [prev setImage:[UIImage imageNamed:@"arrow_up"] forState:UIControlStateNormal];
        prev.bounds = CGRectMake(0, 0, 24.f, 24.f);
        prev.translatesAutoresizingMaskIntoConstraints = NO;
        [prev addTarget:self action:@selector(didTapSearchPrevious) forControlEvents:UIControlEventTouchUpInside];
        prev.accessibilityHint = @"Previous search result";
        
        frame = prev.bounds;
        
        [searchView addSubview:prev];
        
        [prev.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [prev.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [prev.leadingAnchor constraintEqualToAnchor:searchView.leadingAnchor constant:8.f].active = YES;
        [prev.centerYAnchor constraintEqualToAnchor:searchView.centerYAnchor].active = YES;
        
        UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
        [next setImage:[UIImage imageNamed:@"arrow_down"] forState:UIControlStateNormal];
        next.bounds = CGRectMake(0, 0, 24.f, 24.f);
        next.translatesAutoresizingMaskIntoConstraints = NO;
        [next addTarget:self action:@selector(didTapSearchNext) forControlEvents:UIControlEventTouchUpInside];
        next.accessibilityHint = @"Next search result";
        
        frame = next.bounds;
        
        [searchView addSubview:next];
        
        [next.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [next.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [next.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor constant:8.f].active = YES;
        [next.centerYAnchor constraintEqualToAnchor:searchView.centerYAnchor].active = YES;
        
        prev.tintColor = UIColor.blackColor;
        next.tintColor = UIColor.blackColor;
        
        UIButton *done = [UIButton buttonWithType:UIButtonTypeSystem];
        done.translatesAutoresizingMaskIntoConstraints = NO;
        done.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        [done setTitle:@"Done" forState:UIControlStateNormal];
        [done setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [done sizeToFit];
        
        done.accessibilityHint = @"Dismiss search";
        
        [done addTarget:self action:@selector(didTapSearchDone) forControlEvents:UIControlEventTouchUpInside];
        
        frame = done.bounds;
        
        [searchView addSubview:done];
//        [done.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [done.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [done.trailingAnchor constraintEqualToAnchor:searchView.trailingAnchor constant:-8.f].active = YES;
        [done.centerYAnchor constraintEqualToAnchor:searchView.centerYAnchor].active = YES;
        
        self.searchPrevButton = prev;
        self.searchNextButton = next;
        
        UIColor *tint = theme.tintColor;
        prev.tintColor = tint;
        next.tintColor = tint;
        [done setTitleColor:tint forState:UIControlStateNormal];
        
        self.searchPrevButton.enabled = NO;
        self.searchNextButton.enabled = NO;
        
        self.searchView = searchView;
    }
    
    return _searchView;
}

#pragma mark - State Restoration

NSString * const kArticleData = @"ArticleData";
NSString * const kScrollViewSize = @"ScrollViewContentSize";
NSString * const kScrollViewOffset = @"ScrollViewOffset";

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    FeedItem *item = [coder decodeObjectForKey:kArticleData];
    
    if (item != nil) {
        ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
        return vc;
    }
    
    return nil;
    
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.item forKey:kArticleData];
    [coder encodeCGSize:self.scrollView.contentSize forKey:kScrollViewSize];
    [coder encodeCGPoint:self.scrollView.contentOffset forKey:kScrollViewOffset];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
    FeedItem * item = [coder decodeObjectForKey:kArticleData];
    
    if (item) {
        _isRestoring = YES;
        
        [self setupArticle:item];
        
        weakify(self);
        
        CGSize size = [coder decodeCGSizeForKey:kScrollViewSize];
        CGPoint offset = [coder decodeCGPointForKey:kScrollViewOffset];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            self.scrollView.contentSize = size;
            [self.scrollView setContentOffset:offset animated:NO];
        });
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([object isKindOfClass:AVPlayer.class] && [keyPath isEqualToString:propSel(rate)]) {
        
        [object removeObserver:self forKeyPath:propSel(rate) context:KVO_PlayerRate];
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
