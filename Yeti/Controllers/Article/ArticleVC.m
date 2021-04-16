//
//  ArticleVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import "Elytra-Swift.h"
//#import <Networking/Networking-Swift.h>

#import "ArticleAuthorView.h"

#import "AppDelegate.h"

//#import "Content.h"
#import "YetiConstants.h"
#import "CheckWifi.h"

#import "NSAttributedString+Trimming.h"
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>
#import "NSDate+DateTools.h"
#import "NSString+HTML.h"
#import "NSString+Levenshtein.h"
#import "NSString+CJK.h"
#import "CodeParser.h"

#import "TypeFactory.h"

#import <SafariServices/SafariServices.h>

#import "YTPlayer.h"
#import "YTExtractor.h"
#import "NSString+ImageProxy.h"

#import "Paragraph.h"
#import "Heading.h"
#import "Blockquote.h"
#import "List.h"
#import "Aside.h"
#import "Youtube.h"
#import "Image.h"
#import "PaddedLabel.h"
#import "Gallery.h"
#import "GalleryCell.h"
#import "LineBreak.h"
#import "Code.h"
#import "Tweet.h"
#import "TweetImage.h"

#import <SDWebImage/SDWebImage.h>

#import <LinkPresentation/LinkPresentation.h>

static void *KVO_PlayerRate = &KVO_PlayerRate;

typedef NS_ENUM(NSInteger, ArticleVCState) {
    ArticleVCStateUnknown,
    ArticleVCStateLoading,
    ArticleVCStateLoaded,
    ArticleVCStateError,
    ArticleVCStateEmpty
};

@interface ArticleVC () <UIScrollViewDelegate, UITextViewDelegate, UIViewControllerRestoration, AVPlayerViewControllerDelegate, ArticleAuthorViewDelegate, UIPointerInteractionDelegate, TextSharing> {
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
@property (nonatomic, strong, readwrite) NSPointerArray *images;

@property (nonatomic, strong) NSPointerArray *videos;

@property (nonatomic, strong) CodeParser *codeParser;

@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, assign) ArticleVCState state;

@property (nonatomic, strong) NSError *articleLoadingError;
@property (weak, nonatomic) IBOutlet UILabel *errorTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIStackView *errorStackView;

@property (nonatomic, strong) YTExtractor *ytExtractor;

/// These are special handlers for rendering specific blog articles.
@property (assign) BOOL isiOSIconGallery;

@end

@implementation ArticleVC

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (instancetype)initWithItem:(Article *)item
{
    if (self = [super initWithNibName:NSStringFromClass(ArticleVC.class) bundle:nil]) {
        
        self.item = item;
        
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.loader.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    }
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.state = ArticleVCStateLoading;
    
#if TARGET_OS_MACCATALYST
    
    if (self.isExploring == NO) {
        self.navigationController.navigationBar.hidden = YES;
    }
    
    self.scrollView.contentInset = UIEdgeInsetsMake(12.f, 0, 44.f, 0);
    
#else
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(0.f, 0.f, 44.f, 0.f);

    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        || self.splitViewController.view.bounds.size.height < 814.f) {

        if (PrefsManager.sharedInstance.useToolbar) {
            self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0.f, 0.f, 0.f);
            self.scrollView.contentInset = UIEdgeInsetsMake(LayoutPadding * 2, 0, 12.f, 0);
        }
        else {
            self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 88.f, 0);
            self.scrollView.contentInset = UIEdgeInsetsMake(LayoutPadding * 2, 0, 0, 0);
        }

    }
    else if (self.splitViewController.view.bounds.size.height > 814.f
             && self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {

        if (PrefsManager.sharedInstance.useToolbar) {
            self.additionalSafeAreaInsets = UIEdgeInsetsMake(16.f, 0.f, 0.f, 0.f);
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 12.f, 0);
        }
        else {
            self.additionalSafeAreaInsets = UIEdgeInsetsMake(16.f, 0.f, 52.f, 0.f);
        }

    }
    
#endif

    self.scrollView.restorationIdentifier = self.restorationIdentifier;
    
    [self setupArticle:self.currentArticle];
    
    UILayoutGuide *readable = self.scrollView.readableContentGuide;
    
    [self setupHelperView];
    
    [self.stackView.leadingAnchor constraintEqualToAnchor:readable.leadingAnchor constant:LayoutPadding/2.f].active = YES;
    [self.stackView.trailingAnchor constraintEqualToAnchor:readable.trailingAnchor constant:-LayoutPadding/2.f].active = YES;
    
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    weakify(self);
    
    if (!(self.item != nil && ((Article *)(self.item)).content != nil
          && (((Article *)(self.item)).bookmarked == YES || ((Article *)(self.item)).textFromContent != nil) )) {
        
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
    
    self.state = (((Article *)(self.item)).content && ((Article *)(self.item)).content.count) ? ArticleVCStateLoaded : ArticleVCStateLoading;
    
    self.ytExtractor = [[YTExtractor alloc] init];
    
    if (self.initialInteractivePopGestureRecognizerDelegate == nil) {
        self.initialInteractivePopGestureRecognizerDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
    }
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

#if TARGET_OS_MACCATALYST
    
    if (self.isExternalWindow == NO) {
        [UIMenuSystem.mainSystem setNeedsRebuild];
    }
    
#else
    
    [self setupToolbar:self.traitCollection];
    
    if (SharedPrefs.hideBars == YES) {
        
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
        
        self.navigationController.hidesBarsOnSwipe = YES;
        
        [self.navigationController.barHideOnSwipeGestureRecognizer addTarget:self action:@selector(didUpdateNavBarAppearance:)];
        
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
#endif
    
    [self didUpdateTheme];
    
    if (!_hasRendered) {
        
        [self.loader startAnimating];
        
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (self.helperView != nil) {
        self.helperView.tintColor = self.view.tintColor;
    }

    [self becomeFirstResponder];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
#if !TARGET_OS_MACCATALYST
    
    if (SharedPrefs.hideBars == YES) {
        
        if (self.navigationController.isNavigationBarHidden == YES) {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
        
        self.navigationController.interactivePopGestureRecognizer.delegate = self.initialInteractivePopGestureRecognizerDelegate;
        
        self.navigationController.hidesBarsOnSwipe = NO;
        
        [self.navigationController.barHideOnSwipeGestureRecognizer removeTarget:self action:@selector(didUpdateNavBarAppearance:)];
        
    }
    
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    
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

- (BOOL)definesPresentationContext {
    
    return YES;
    
}

- (void)dealloc {
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    } @catch (NSException *exc) {}
}

#pragma mark -

- (void)setupHelperView {
    
#if TARGET_OS_MACCATALYST
    return;
#endif
    
    if (self.providerDelegate == nil)
        return;
    
    if (PrefsManager.sharedInstance.useToolbar == YES) {
        return;
    }
    
    ArticleHelperView *helperView = [[ArticleHelperView alloc] initWithNib];
    helperView.frame = CGRectMake((self.view.bounds.size.width - 190.f) / 2.f, self.view.bounds.size.height - 44.f - 32.f, 190.f, 44.f);
    
    UIUserInterfaceIdiom idiom = self.traitCollection.userInterfaceIdiom;
    UIUserInterfaceSizeClass sizeClass = self.traitCollection.horizontalSizeClass;
    
    [self.view addSubview:helperView];
    
    if (idiom == UIUserInterfaceIdiomPad || sizeClass == UIUserInterfaceSizeClassRegular) {
        // on iPad, wide
        // we also push it slightly lower to around where the hands usually are on iPads
        if (idiom == UIUserInterfaceIdiomPad) {
            [helperView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:(self.view.bounds.size.height / 4.f)].active = YES;
            [helperView.heightAnchor constraintEqualToConstant:190.f].active = YES;
            [helperView.widthAnchor constraintEqualToConstant:44.f].active = YES;
            helperView.bottomConstraint = [helperView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-LayoutPadding];
            
            helperView.bottomConstraint.active = YES;
            helperView.stackView.axis = UILayoutConstraintAxisVertical;
        }
        else {
            [helperView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
            [helperView.widthAnchor constraintEqualToConstant:190.f].active = YES;
            [helperView.heightAnchor constraintEqualToConstant:44.f].active = YES;
            helperView.bottomConstraint = [helperView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-32.f];
            helperView.bottomConstraint.active = YES;
        }
        
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
    
    BOOL next = [self.providerDelegate hasNextArticleForArticle:self.item];
    BOOL previous = [self.providerDelegate hasPreviousArticleForArticle:self.item];
    
    [self.helperView.previousArticleButton setEnabled:previous];
    
    [self.helperView.nextArticleButton setEnabled:next];
    // UIActivityContentViewController
    self.helperView.startOfArticle.enabled = NO;
    self.helperView.endOfArticle.enabled = YES;
}

#pragma mark -

- (void)didUpdateTheme {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(didUpdateTheme) withObject:nil waitUntilDone:NO];
        return;
    }
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.scrollView.backgroundColor = UIColor.systemBackgroundColor;
    
    if (self.helperView != nil) {
        self.helperView.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        self.helperView.tintColor = self.view.tintColor;
        [self.helperView updateShadowPath];
    }
    
}

- (void)didChangePreferredContentSize {
    
    if (self.state == ArticleVCStateLoading) {
        return;
    }
    
    Paragraph.paragraphStyle = nil;
    
    UIGraphicsBeginImageContextWithOptions(self.scrollView.superview.bounds.size, YES, 0.0);
    [self.scrollView drawViewHierarchyInRect:self.scrollView.superview.bounds afterScreenUpdates:NO];
    UIImage * snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect frame = self.scrollView.superview.bounds;
    
    UIImageView *snapshotView = [[UIImageView alloc] initWithFrame:frame];
    snapshotView.image = snapshot;
    snapshotView.alpha = 1;
    
    [self.scrollView.superview insertSubview:snapshotView aboveSubview:self.scrollView];
    
    self.navigationController.view.backgroundColor = UIColor.systemBackgroundColor;
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.scrollView.backgroundColor = UIColor.systemBackgroundColor;
    
    [self setupArticle:self.currentArticle];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateKeyframesWithDuration:0.3 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced|UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            
            snapshotView.alpha = 0;
            
        } completion:^(BOOL finished) {
            
            [snapshotView removeFromSuperview];
            
        }];
        
    });
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        
        [self updateImagesForNewInterfaceStyle];
        
    }
    
    [super traitCollectionDidChange:previousTraitCollection];
    
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
        
//        if (firstVisible) {
//            CGFloat yOffset = firstVisible.frame.origin.y + (self.scrollView.bounds.size.height / 2);
//            [self.scrollView setContentOffset:CGPointMake(0, yOffset)];
//        }
    }];
}

- (void)updateImagesForNewInterfaceStyle {
    
    UIUserInterfaceStyle style = self.traitCollection.userInterfaceStyle;
    
    for (Image *imageView in self.images) { @autoreleasepool {
        
        Image *view = nil;
        
        if ([imageView respondsToSelector:@selector(imageView)] && [imageView.imageView respondsToSelector:@selector(image)]) {
            
            view = imageView;
            
        }
//        else if ([imageView respondsToSelector:@selector(image)]) {
//            
//            view =
//            
//        }
        
        if (view != nil) {
            
            if (style == UIUserInterfaceStyleDark && view.darkModeURL != nil) {
                
                if ([[view.imageView sd_imageURL] isEqual:view.darkModeURL] == NO) {
                    
                    [view cancelImageLoading];
                    [view setImageWithURL:view.darkModeURL];
                    
                }
                
            }
            else {
                
                if ([[view.imageView sd_imageURL] isEqual:view.URL] == NO) {
                    
                    [view cancelImageLoading];
                    [view setImageWithURL:view.URL];
                    
                }
                
            }
            
        }
        
    } }
    
}

#pragma mark - <ArticleHandler>

- (void)setState:(ArticleVCState)state {
    
    [self setState:state isChangingArticle:YES];
    
}

- (void)setState:(ArticleVCState)state isChangingArticle:(BOOL)isChangingArticle {
    
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
        case ArticleVCStateLoading:
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
        case ArticleVCStateLoaded:
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
                
                if (isChangingArticle) {
                    
                    [self setupHelperViewActions];
                    [self setupToolbar:self.traitCollection];
                    
                }
                
            }];
            
        }
            break;
        case ArticleVCStateError:
        {
            if (!self.articleLoadingError) {
                break;
            }
            
            [self.loader stopAnimating];
            self.loader.hidden = YES;
            
            self.stackView.hidden = YES;
            
            self.errorTitleLabel.text = @"Error loading the article";
            self.errorDescriptionLabel.text = [self.articleLoadingError localizedDescription];
            
            self.errorTitleLabel.textColor = UIColor.labelColor;
            self.errorDescriptionLabel.textColor = UIColor.secondaryLabelColor;
            
            for (UILabel *label in @[self.errorTitleLabel, self.errorDescriptionLabel]) {
                label.backgroundColor = UIColor.systemBackgroundColor;
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

- (Article *)currentArticle
{
    return self.item;
}

- (void)setupArticle:(Article *)article {
    
    if (!article)
        return;
    
    /* This block may not be necessary with local storage
     *
    if (self.item) {
        
        if (((Article *)(self.item)).isBookmarked == NO) {
            if (_isRestoring == YES) {
                _isRestoring = NO;
            }
            else {
                // only do this when not restoring state.
                // and for non-microblog posts
                if ([(((Article *)(self.item)).articleTitle ?: @"") isBlank] == NO) {
                
                    ((Article *)(self.item)).content = nil;
                    
                }
            }
        }
    }
    */
    
    BOOL isChangingArticle = self.item && ((Article *)(self.item)).identifier.integerValue != article.identifier.integerValue;
    
    self.item = article;
    
    NSDate *start = NSDate.date;
    
    if (((Article *)(self.item)).content && ((Article *)(self.item)).content.count) {
        
        [self setState:ArticleVCStateLoading isChangingArticle:isChangingArticle];
        
        [self _setupArticle:self.item start:start isChangingArticle:isChangingArticle];
        return;
    }
    
    self.state = ArticleVCStateLoading;
    
    weakify(self);
    
    [self.coordinator getArticle:((Article *)(self.item)).identifier feedID:((Article *)(self.item)).feedID completion:^(NSError * _Nullable error, Article * _Nonnull responseObject) {
       
        strongify(self);

        if (error != nil) {
            self.articleLoadingError = error;
            self.state = ArticleVCStateError;
            return;
        }
        
        // since we're only fetching content and fulltext from here, update those
        if (((Article *)(self.item)).title == nil && ((Article *)(self.item)).content.count == 0) {
            [((Article *)(self.item)) copyFromArticle:responseObject];
        }
        else {
            ((Article *)(self.item)).content = responseObject.content;
            ((Article *)(self.item)).fulltext = responseObject.fulltext;
        }
        
        [self _setupArticle:self.item start:start isChangingArticle:isChangingArticle];
        
    }];
    
}

- (BOOL)_imageURL:(NSURL *)url appearsInContent:(Content *)content {
    
    NSString *path = url.absoluteString;
    
    if ([path containsString:@"?"]) {
        
        path = [path substringToIndex:[path rangeOfString:@"?" options:NSBackwardsSearch].location];
        
    }
    
    if (([content.type isEqualToString:@"image"] || [content.type isEqualToString:@"img"])) {
        
        NSString *comparing = content.url.absoluteString.copy;
        
        if ([comparing containsString:@"?"]) {
            
            comparing = [comparing substringToIndex:[comparing rangeOfString:@"?" options:NSBackwardsSearch].location];
            
        }
        
        if ([comparing isEqualToString:path]) {
            
            return YES;
            
        }
        
        if (content.srcSet != nil) {
            
            NSArray *values = [content.srcSet allValues];
            
            values = [values rz_map:^id(id obj, NSUInteger id, NSArray *array) {
               
                if ([obj isKindOfClass:NSDictionary.class]) {
                    
                    return [(NSDictionary *)obj allValues];
                    
                }
                
                return obj;
                
            }];
            
            values = [values rz_flatten];
            
            if ([values indexOfObject:url] != NSNotFound) {
                
                return YES;
                
            }
            
        }
    }
    else if (content.items != nil) {
        
        Content *appearing = [content.items rz_find:^BOOL(Content * objx, NSUInteger idxx, NSArray *arrayx) {
           
            return [self _imageURL:url appearsInContent:objx];
            
        }];
        
        return appearing != nil;
        
    }
    else if (content.images != nil) {
        
        Content *appearing = [content.images rz_find:^BOOL(Content *objx, NSUInteger idxx, NSArray *arrayx) {
           
            return [self _imageURL:url appearsInContent:objx];
            
        }];
        
        return appearing != nil;
        
    }
    
    return NO;
    
}

- (BOOL)imageURLAppearsInContent:(NSURL *)url {
    
    __block BOOL included = NO;
    
    [((Article *)(self.item)).content enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        included = [self _imageURL:url.copy appearsInContent:obj];
        
        if (included == YES) {
            *stop = YES;
        }
        
    }];
    
    return included;
    
}

- (void)_setupArticle:(Article *)responseObject start:(NSDate *)start isChangingArticle:(BOOL)isChangingArticle {
    
    if (self == nil) {
        return;
    }
    
    weakify(self);
    
    self.item = responseObject;
    
    if (((Article *)(self.item)).url != nil && [[((Article *)(self.item)).url.absoluteString lowercaseString] containsString:@"iosicongallery"]) {
        self.isiOSIconGallery = YES;
    }
    
//    if (((Article *)(self.item)).isRead == NO) {
//        [self didTapRead:nil];
//    }
    
    BOOL isYoutubeVideo = [((Article *)(self.item)).url.absoluteString containsString:@"youtube.com/watch"];
    
    // add Body
    [self addTitle];
    
    // iOS 13 shouldn't need it and handle it well.
#if !TARGET_OS_MACCATALYST
    if (((Article *)(self.item)).content.count > 30) {
        self->_deferredProcessing = YES;
    }
#endif
    
    if (isYoutubeVideo == YES) {
        
        Content *content = [Content new];
        content.type = @"youtube";
        content.url = ((Article *)(self.item)).url;
        
        [self addYoutube:content];
        
    }
//    else if ([((Article *)(self.item)).url.absoluteString containsString:@"trailers.apple.com"]) {
//        
//        LPMetadataProvider *provider = [LPMetadataProvider new];
//        [provider startFetchingMetadataForURL:((Article *)(self.item)).url completionHandler:^(LPLinkMetadata * _Nullable metadata, NSError * _Nullable error) {
//           
//            if (error != nil) {
//                [AlertManager showGenericAlertWithTitle:@"Error Fetching Preview" message:error.localizedDescription];
//                return;
//            }
//            
//        }];
//        
//    }
    
    NSMutableArray <NSURL *> *imagesFromEnclosures = @[].mutableCopy;
    
    if (((Article *)(self.item)).coverImage != nil) {
        
        if ([self imageURLAppearsInContent:((Article *)(self.item)).coverImage] == NO) {
            
            [imagesFromEnclosures addObject:((Article *)(self.item)).coverImage];
            
            /*
             * In the event of a Youtube video, we add the video itself
             * instead of the cover and then the video.
             */
            if (isYoutubeVideo == NO && ((Article *)(self.item)).coverImage) {
                Content *content = [Content new];
                content.type = @"image";
                content.url = ((Article *)(self.item)).coverImage;

                weakify(self);

                asyncMain(^{
                    strongify(self);
                    [self addImage:content];
                });
            }
            
        }
        
    }
    
    if (((Article *)(self.item)).enclosures && ((Article *)(self.item)).enclosures.count) {
        
        NSArray *const IMAGE_TYPES = @[@"image", @"image/jpeg", @"image/jpg", @"image/png", @"image/webp"];
        NSArray *const VIDEO_TYPES = @[@"video", @"video/h264", @"video/mp4", @"video/webm"];
        
        // check for images
        NSArray <Enclosure *> *enclosures = [((Article *)(self.item)).enclosures rz_filter:^BOOL(Enclosure *obj, NSUInteger idx, NSArray *array) {
           
            BOOL isImage = obj.type && [IMAGE_TYPES containsObject:obj.type];
            
            // ensure it doesn't appear in the content
            if (isImage) {
                
                isImage = ![self imageURLAppearsInContent:obj.url];
                
            }
            
            return isImage;
            
        }];
        
        if (enclosures.count) {
            
            if (enclosures.count == 1) {
                Enclosure *enc = [enclosures firstObject];
                
                if (enc.url && enc.url.absoluteString) {
                    // single image, add as cover
                    Content *content = [Content new];
                    content.type = @"image";
                    content.url = enclosures.firstObject.url;
                    content.fromEnclosure = YES;
                    
                    // only add to the gallery if the image hasn't already been included.
                    if ([imagesFromEnclosures indexOfObject:content.url] == NSNotFound) {

                        [imagesFromEnclosures addObject:content.url];
                        
                        ((Article *)(self.item)).content = [@[content] arrayByAddingObjectsFromArray:((Article *)(self.item)).content];
                        
                    }
                    
                }
            }
            else {
                // Add as a gallery
                
                Content *content = [Content new];
                content.type = @"gallery";
                content.fromEnclosure = YES;
                
                NSMutableArray *images = [NSMutableArray arrayWithCapacity:enclosures.count];
                
                for (Enclosure *enc in enclosures) {
                    
                    if (enc.url && enc.url.absoluteString) {
                        // single image, add as cover
                        Content *subcontent = [Content new];
                        subcontent.type = @"image";
                        subcontent.url = enc.url;
                        subcontent.fromEnclosure = YES;
                        
                        // only add to the gallery if the image hasn't already been included.
                        if ([imagesFromEnclosures indexOfObject:subcontent.url] == NSNotFound) {

                            [imagesFromEnclosures addObject:subcontent.url];
                            
                            [images addObject:subcontent];
                            
                        }
                    
                    }
                    
                }
                
                content.images = images;
                
                ((Article *)(self.item)).content = [@[content] arrayByAddingObjectsFromArray:((Article *)(self.item)).content];
                
            }
            
        }
        
        enclosures = [((Article *)(self.item)).enclosures rz_filter:^BOOL(Enclosure *obj, NSUInteger idx, NSArray *array) {
           
            return obj.type && [VIDEO_TYPES containsObject:obj.type];
            
        }];
        
        if (enclosures.count) {
            
            for (Enclosure *enc in enclosures) { @autoreleasepool {
                
                if (enc.url && enc.url.absoluteString) {
                    // single image, add as cover
                    Content *subcontent = [Content new];
                    subcontent.type = @"video";
                    subcontent.url = enc.url;
                    
                    ((Article *)(self.item)).content = [@[subcontent] arrayByAddingObjectsFromArray:((Article *)(self.item)).content];
                }
                
            } }
            
        }
        
    }
    
    [((Article *)(self.item)).content enumerateObjectsUsingBlock:^(Content *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            @autoreleasepool {
                
                if (idx == 0
                    && [obj.type isEqualToString:@"paragraph"]
                    && [obj.content isKindOfClass:NSString.class]
                    && [obj.content containsString:@"This article was incorrectly formatted"]) {
                    
                    if (obj.ranges == nil) {
                        obj.ranges = @[];
                    }
                    
                    ContentRange *rangeObj = [ContentRange new];
                    rangeObj.element = @"anchor";
                    rangeObj.url = ((Article *)(self.item)).url;
                    rangeObj.nsRange = [obj.content rangeOfString:@"click here"];
                    
                    if ([obj.ranges indexOfObject:rangeObj] == NSNotFound) {
                        obj.ranges = [obj.ranges arrayByAddingObject:rangeObj];
                    }
                    
                }
                
                [self processContent:obj index:idx imagesFromEnclosures:imagesFromEnclosures];
            }
        });
        
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        if (self == nil) {
            return;
        }
        
        self->_last = nil;
        
        NSLog(@"Processing: %@", @([NSDate.date timeIntervalSinceDate:start]));
        
        
        if (self.item && ((Article *)(self.item)).read == NO) {

            if (self.providerDelegate && [self.providerDelegate respondsToSelector:@selector(userMarkedArticle:read:)]) {
                [self.providerDelegate userMarkedArticle:self.item read:YES];
            }
            else {
                // Handle from directly marking on the FeedsManager
            }
        }
        
        [self.stackView layoutIfNeeded];
        
        [self scrollViewDidScroll:self.scrollView];
        
        CGSize contentSize = self.scrollView.contentSize;
        contentSize.width = self.view.bounds.size.width;
        
        self.scrollView.contentSize = contentSize;
        
        NSLogDebug(@"ScrollView contentsize: %@", NSStringFromCGSize(contentSize));
        
        [self setState:ArticleVCStateLoaded isChangingArticle:isChangingArticle];
        
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
    
    NSString *author = nil;
    
    if (((Article *)(self.item)).author) {
        if ([((Article *)(self.item)).author isKindOfClass:NSString.class]) {
            author = ((Article *)(self.item)).author;
        }
        else {
            author = [((Article *)(self.item)).author valueForKey:@"name"];
        }
    }
    else {
        author = @"Unknown";
    }
    
    author = [author stringByStrippingHTML];
    
    if ([author isBlank] == NO) {
        author = [author stringByAppendingString:@" • "];
    }
    
    Feed *feed = [self.coordinator feedFor:((Article *)(self.item)).feedID];

    NSString *firstLine = feed != nil ? feed.displayTitle : nil;
    NSString *timestamp = nil;
    
    timestamp = [[NSRelativeDateTimeFormatter new] localizedStringForDate:((Article *)(self.item)).timestamp relativeToDate:NSDate.date];
    
    NSString *sublineText = formattedString(@"%@%@", author, timestamp);
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

    para.paragraphSpacingBefore = 0.f;
    para.paragraphSpacing = 0.f;

    ArticleLayoutFont fontPref = SharedPrefs.paraTitleFont ?: SharedPrefs.articleFont;
    CGFloat baseFontSize = 32.f;

    if (((Article *)(self.item)).title.length > 24) {
        baseFontSize = 26.f;
    }
    
    NSString *fontName = [fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""];
    
    if ([fontName containsString:@"Atkinson"]) {
        fontName = [[fontName stringByReplacingOccurrencesOfString:@" " withString:@""] stringByAppendingString:@"-Bold"];
    }
    else {
        fontName = [fontName.capitalizedString stringByAppendingString:@"-Bold"];
    }

    UIFont *baseFont = [fontPref isEqualToString:ALPSystem] ? [UIFont boldSystemFontOfSize:baseFontSize] : [UIFont fontWithName:fontName size:baseFontSize];

    UIFont * titleFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:baseFont];
    
    ArticleAuthorView *authorView = [[ArticleAuthorView alloc] initWithNib];
    authorView.delegate = self;
    
    if ([Paragraph languageDirectionForText:((Article *)(self.item)).title] == NSLocaleLanguageDirectionRightToLeft) {
        
        authorView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        
        authorView.titleLabel.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        para.alignment = NSTextAlignmentRight;
        
    }

    NSDictionary *baseAttributes = @{NSFontAttributeName : titleFont,
                                     NSForegroundColorAttributeName: UIColor.labelColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: @0,
                                     };

    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:((Article *)(self.item)).title attributes:baseAttributes];
    
    // this will be reused later after setting up the label.
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 48.f);
    
#if TARGET_OS_MACCATALYST
    frame.size.height = 120.f;
#endif
    
    authorView.frame = frame;
    
    authorView.titleLabel.attributedText = attrs;
    authorView.blogLabel.text = firstLine;
    authorView.authorLabel.text = sublineText;
    
#if !TARGET_OS_MACCATALYST
    for (UILabel *label in @[authorView.titleLabel, authorView.blogLabel, authorView.authorLabel]) {
        [label sizeToFit];
    }
    
    [authorView sizeToFit];
    
    CGSize fittingSize = [authorView systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX) withHorizontalFittingPriority:999 verticalFittingPriority:999];
    
    if (fittingSize.height != CGFLOAT_MAX && fittingSize.height > frame.size.height) {
        frame.size = fittingSize;
    }
    
    authorView.frame = frame;
#endif
    
    // Hide full-text button for Youtube videos.
    authorView.mercurialButton.hidden = ([((Article *)(self.item)).url.absoluteString containsString:@"youtube.com/watch"]);
    
    authorView.mercurialed = ((Article *)(self.item)).fulltext;
    
    [self.stackView addArrangedSubview:authorView];
    
    // came from a push notification
    // or the providerDelegate is a non-base-DetailFeedVC (eg. DetailCustomVC)
    
    if (self.providerDelegate == nil ||
        (self.providerDelegate != nil && [self.providerDelegate isMemberOfClass:FeedVC.class] == NO)) {

        // the blog label should redirect to the blog
        authorView.blogLabel.textColor = SharedPrefs.tintColor;
        [authorView.blogLabel setNeedsDisplay];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnBlogLabel:)];
        tap.numberOfTapsRequired = 1;
        tap.delaysTouchesBegan = YES;
        tap.delaysTouchesEnded = NO;

        if (@available(iOS 13.4, *)) {

            UIPointerInteraction *interaction = [[UIPointerInteraction alloc] initWithDelegate:self];
            [authorView.blogLabel addInteraction:interaction];

        }

        [authorView.blogLabel addGestureRecognizer:tap];

    }
    
}

#pragma mark -

- (BOOL)showImage {
    if ([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingNever])
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

- (void)processContent:(Content *)content index:(NSUInteger)idx imagesFromEnclosures:(NSArray <NSURL *> *)imagesFromEnclosures {
    
    /**
     * 1. Check the first item in the list
     * 2. If it's an image
     * 3. The article declares a cover image
     */
    BOOL isImage = [content.type isEqualToString:@"img"] || [content.type isEqualToString:@"image"];
    BOOL hasCover = ((Article *)(self.item)).coverImage != nil;
    BOOL imageFromEnclosure = isImage ? ([imagesFromEnclosures indexOfObject:content.url] != NSNotFound) : NO;
    
    if (idx == 0 && isImage && imageFromEnclosure == YES) {
       return;
    }
   
    if (idx == 0 && isImage && hasCover && imagesFromEnclosures.count) {
       // check if the cover image and the first image
       // are the same entities
       NSURLComponents *coverComponents = [NSURLComponents componentsWithString:((Article *)(self.item)).coverImage.absoluteString];
       NSURLComponents *imageComponents = [NSURLComponents componentsWithString:content.url.absoluteString];
       
       if ([coverComponents.path isEqualToString:imageComponents.path]) {
           return;
       }
    }
    
#ifdef DEBUG
    if (content.url) {
        NSLog(@"URL: %@", content.url);
    }
#endif
    
    if ([content.type isEqualToString:@"container"] || [content.type isEqualToString:@"div"]
        || ([content.type isEqualToString:@"anchor"] && content.items.count)
        ) {
        
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
                
                if ([content.type isEqualToString:@"anchor"]
                    && content.url != nil
                    && [subcontent.type isEqualToString:@"paragraph"]
                    && subcontent.content != nil
                    && subcontent.content.length) {
                    
                    // add the URL as a range to the entire paragraph.
                    ContentRange *range = [ContentRange new];
                    range.nsRange = NSMakeRange(0, subcontent.content.length);
                    range.element = @"anchor";
                    range.url = content.url;
                    
                    if (subcontent.ranges == nil) {
                        subcontent.ranges = @[];
                    }
                    else {
                        // check if this range already exists
                        NSUInteger indexOfRange = [subcontent.ranges indexOfObject:range];
                        
                        if (indexOfRange != NSNotFound) {
                            range = nil;
                        }
                        
                    }
                    
                    if (range != nil) {
                        subcontent.ranges = [subcontent.ranges arrayByAddingObject:range];
                    }
                    
                }
                
                [self processContent:subcontent index:idx imagesFromEnclosures:imagesFromEnclosures];
                
                idx++;
            }}
        }
        
    }
    else if ([content.type isEqualToString:@"p"] || [content.type isEqualToString:@"paragraph"] || [content.type isEqualToString:@"cite"] || [content.type isEqualToString:@"span"]) {
        
        if (content.content.length && [content.type isEqualToString:@"noscript"] == NO) {
            [self addParagraph:content caption:NO];
        }
        else if (content.items) {
            
            for (Content *subcontent in content.items) {
                [self processContent:subcontent index:idx imagesFromEnclosures:imagesFromEnclosures];
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
    else if ([content.type isEqualToString:@"list"] || [content.type containsString:@"list"]
             || [content.type isEqualToString:@"ul"] || [content.type isEqualToString:@"ol"]) {
        
        [self addList:content];
        
    }
    else if ([content.type isEqualToString:@"anchor"]) {
        
        NSArray <Content *> *subcontent = [content.items rz_filter:^BOOL(Content *obj, NSUInteger idx, NSArray *array) {
            return [obj.type isEqualToString:@"linebreak"] == NO;
        }];
        
        if (subcontent.count == 1 && [subcontent[0].type isEqualToString:@"image"]) {
            [self addImage:subcontent.firstObject link:content.url];
            return;
        }
        
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
        
        content.images = [content.images rz_filter:^BOOL(Content *obj, NSUInteger idx, NSArray *array) {
           
            return obj.url != nil && [obj.url.absoluteString containsString:@".gravatar.com/"] == NO;
            
        }];
        
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
                    [self processContent:item index:idx imagesFromEnclosures:imagesFromEnclosures];
                }
            }
            else {
                for (Content *sub in content.items) { @autoreleasepool {
                    
                    [self processContent:sub index:idx imagesFromEnclosures:imagesFromEnclosures];
                    
                } }
            }
        }
        
    }
    else if ([content.type isEqualToString:@"pre"] || [content.type isEqualToString:@"code"]) {
        
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
        
        CGFloat halfPixel = 1.f;

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, halfPixel)];

        line.userInteractionEnabled = NO;
        line.backgroundColor = UIColor.separatorColor;
        line.translatesAutoresizingMaskIntoConstraints = NO;
        
        [line.heightAnchor constraintEqualToConstant:halfPixel].active = YES;
        
        [self.stackView addArrangedSubview:line];
        
        _last = line;
        
    }
    else if ([content.type isEqualToString:@"script"]) {
        // wont be handled at the moment
    }
    else if ([content.type isEqualToString:@"video"]) {
        
        [self addVideo:content];
        
    }
    else {
        NSLog(@"Unhandled node: %@", content);
    }
}

- (void)addParagraph:(Content *)content caption:(BOOL)caption {
    
    if ([_last isMemberOfClass:Paragraph.class]
        && !caption) {
        // check if we have a duplicate
        Paragraph *lastPara = (Paragraph *)_last;
        
        if(lastPara.isCaption && ([lastPara.text isEqualToString:content.content] || [lastPara.attributedText.string isEqualToString:content.content])) {
            
            return;
            
        }
    }
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, LayoutPadding * 2);
        
    Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
    
    para.textSharingDelegate = self;
    
#if DEBUG_LAYOUT == 1
    para.backgroundColor = UIColor.blueColor;
#endif
    
    para.avoidsLazyLoading = !_deferredProcessing;
    
    if ([_last isMemberOfClass:Heading.class]) {
        
        para.afterHeading = YES;
    }
    
    para.caption = caption;
    
    BOOL rangeAdded = NO;
    
    // check if attributes has href
    if (![content.type isEqualToString:@"paragraph"]) {
        if (content.attributes && [content.attributes valueForKey:@"href"]) {
            NSMutableArray <ContentRange *> *ranges = content.ranges.mutableCopy;
            
            ContentRange *newRange = [ContentRange new];
            newRange.element = @"anchor";
            newRange.nsRange = NSMakeRange(0, content.content.length);
            newRange.url = [NSURL URLWithString:[content.attributes valueForKey:@"href"]];
            
            [ranges addObject:newRange];
            
            content.ranges = ranges.copy;
            rangeAdded = YES;
        }
        else if (content.url) {
            NSMutableArray <ContentRange *> *ranges = content.ranges.mutableCopy;
            
            ContentRange *newRange = [ContentRange new];
            newRange.element = @"anchor";
            newRange.nsRange = NSMakeRange(0, content.content.length);
            newRange.url = content.url;
            
            [ranges addObject:newRange];
            
            content.ranges = ranges.copy;
            rangeAdded = YES;
        }
        else {
            NSMutableArray <ContentRange *> *ranges = content.ranges.mutableCopy;
            
            ContentRange *newRange = [ContentRange new];
            newRange.element = content.type;
            newRange.nsRange = NSMakeRange(0, content.content.length);
            
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
            
            BOOL spaceFlag = NO;
            
            // For CJK paragraphs, we strictly ignore any rangeAdditions we make.
            // Not doing so breaks the formatting as intended by the author making
            // the text one big paragraph and difficult to read. 
            if (rangeAdded == YES && [newAttrs.string containsCJKCharacters] == YES) {
                rangeAdded = NO;
            }
            else if (rangeAdded == NO && attrs.string.length > 0) {
                
                // ensure if the last char from the attrs string
                // is not a whitespace char.
                NSString *lastChar = [attrs.string substringFromIndex:(attrs.string.length - 1)];
                
                // if it is a non-whitespace character, ergo a continuation
                // of the previous para's text, we appead directly.
                if ( [lastChar rangeOfCharacterFromSet:NSCharacterSet.punctuationCharacterSet].location == NSNotFound
                    && [lastChar rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location == NSNotFound) {
                    
                    rangeAdded = YES;
                    
                    // if the new string's first char is an apostrophe
                    // we set the spaceFlag to YES, such that we do not
                    // append a space, and forego that process.
                    
                    if (newAttrs.string.length > 0) {
                        
                        NSString *firstChar = [newAttrs.string substringToIndex:1];
                        
                        if ([firstChar isEqualToString:@"'"]) {
                            spaceFlag = YES;
                        }
                        
                    }
                    
                }
                
            }
            
            if (spaceFlag == NO) {
                
                NSString *accessoryStr = formattedString(@"%@", rangeAdded ? @" " : @"\n\n");
                
                NSAttributedString *accessory = [[NSAttributedString alloc] initWithString:accessoryStr];
                
                [attrs appendAttributedString:accessory];
                
            }
            
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
    
    heading.level = content && content.level ? content.level.integerValue : 1;
    
    [heading setText:content.content ranges:content.ranges attributes:content.attributes];
    
    if (content.identifier && [content.identifier isKindOfClass:NSString.class] && ![content.identifier isBlank]) {
        
        // content identifiers should only be URL safe chars
        NSString *identifier = [content.identifier stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        
        heading.identifier = content.identifier;
        
        NSAttributedString *attrs = heading.attributedText;
        
        NSURL *url = formattedURL(@"%@#%@", ((Article *)(self.item)).url.absoluteString, identifier);
        
        NSMutableDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:MAX(14.f, heading.bodyFont.pointSize - 8.f)]}.mutableCopy;
        
        if (url != nil) {
            attributes[NSLinkAttributeName] = url;
        }
        
        NSMutableAttributedString *prefix = [[NSAttributedString alloc] initWithString:@"🔗 " attributes:attributes].mutableCopy;
        
        [prefix appendAttributedString:attrs];
        heading.attributedText = prefix;
        
#if TARGET_OS_MACCATALYST
        // handle right click from here
        UIContextMenuInteraction * interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        
        [heading addInteraction:interaction];
#endif
        // catalyst handles left click from here
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

- (void)addImage:(Content *)content link:(NSURL *)link {
    
    if (![self showImage])
        return;
    
    // ignores tracking images
    if (content && CGSizeEqualToSize(content.size.size, CGSizeZero) == NO && content.size.width == 1.f && content.size.height == 1.f) {
        return;
    }
    
    NSString *absolute = content.url ? content.url.absoluteString : @"";
    
    // 9mac ads and some tracking scripts
    if (content.url
        && [absolute containsString:@"theoatmeal"] == NO
        && [absolute containsString:@"amazonaws"] == NO 
        && (
            ([absolute containsString:@"ads"] && [absolute containsString:@"assoc"])
            || ([absolute containsString:@"deal"] && [absolute containsString:@"Daily-Deals-"] == NO)
            || ([absolute containsString:@"amaz"]
            || [[absolute lastPathComponent] containsString:@".php"]
            || [[absolute lastPathComponent] containsString:@".js"])
        )) {
        return;
    }
    
    /**
     * Wordpress blogs add stupid emoji images to the content in the RSS feeds
     * but they also include the actual emoji in the alt text. We extract the
     * alt text and use that directly. 
     */
    if (content.url && ([absolute containsString:@"/images/core/emoji"] || [absolute containsString:@"/wpcom-smileys"])) {
        
        NSDictionary *attributes = content.attributes;
        
        if (attributes[@"alt"] != nil) {
            
            if (_last != nil && [_last isMemberOfClass:Paragraph.class]) {
                
                Paragraph *para = (id)_last;
                
                NSMutableAttributedString *mattrs = para.attributedText.mutableCopy;
                
                NSDictionary *textAttributes = @{NSFontAttributeName: para.font ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
                
                NSAttributedString * attrs = [[NSAttributedString alloc] initWithString:attributes[@"alt"] attributes:textAttributes];
                
                [mattrs appendAttributedString:attrs];
                
                para.attributedText = mattrs;
                
            }
            else {
                
                Content *altContent = [Content new];
                altContent.type = @"paragraph";
                altContent.content = attributes[@"alt"];
                
                [self addParagraph:altContent caption:NO];
                
            }
            
        }
        
        return;
        
    }
    
    if ([_last isMemberOfClass:Heading.class] || !_last || [_last isMemberOfClass:Paragraph.class])
        [self addLinebreak];
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    
    if ([content valueForKey:@"size"] && CGSizeEqualToSize(content.size.size, CGSizeZero) == NO) {
        frame.size = content.size.size;
    }
    
    CGFloat scale = (content.size.height + 24.f) / content.size.width;
    
    if (((NSRange)[absolute rangeOfString:@"feeds.feedburner.com"]).location != NSNotFound) {
        // example: http://feeds.feedburner.com/~ff/abduzeedo?d=yIl2AUoC8zA
        return;
    }
    
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
    if (link != nil && [link.absoluteString isBlank] == NO) {
        imageView.link = link;
    }
    
    if (self.isiOSIconGallery) {
        
        imageView.layer.cornerRadius = frame.size.width * (180.f / 1024.f);
        imageView.layer.cornerCurve = kCACornerCurveContinuous;
        imageView.layer.masksToBounds = YES;
        
    }
    
    _last = imageView;
    
    [self.stackView addArrangedSubview:imageView];
    
    if (!CGSizeEqualToSize(content.size.size, CGSizeZero) && scale != NAN) {
        frame.size.width = content.size.width;
        
        if (scale != INFINITY) {
            frame.size.height = frame.size.width * scale;
        }
        else {
            frame.size.height = 200.f;
            scale = frame.size.height / frame.size.height;
        }
        
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
    
    imageView.content = content;
    
    CGFloat width = self.scrollView.bounds.size.width;

    NSURL *url = [content urlCompliantWithPreference:SharedPrefs.imageLoading width:width];
    NSURL *darkModeURL = [content urlCompliantWithPreference:SharedPrefs.imageLoading width:width darkModeOnly:true];

    if (url == nil && darkModeURL == nil) {

        [self.stackView removeArrangedSubview:imageView];
        [imageView removeFromSuperview];

        imageView = nil;

        return;
    }
    
    [self.images addPointer:(__bridge void *)imageView];
    imageView.idx = self.images.count - 1;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnImage:)];
    imageView.userInteractionEnabled = YES;

    [imageView addGestureRecognizer:tap];

    NSURLComponents *comps = [NSURLComponents componentsWithString:url.absoluteString];

    if (comps.host == nil) {

        NSLogDebug(@"No hostname for URL: %@", url);

        NSURLComponents *articleURLComps = [NSURLComponents componentsWithString:((Article *)(self.item)).url.absoluteString];

        articleURLComps.path = [articleURLComps.path stringByAppendingPathComponent:url.absoluteString];

        NSLogDebug(@"Attempted fixed URL: %@", articleURLComps.URL);

        url = articleURLComps.URL;

        if (darkModeURL != nil) {

            articleURLComps.path = darkModeURL.absoluteString;

            darkModeURL = articleURLComps.URL;

        }

    }

    imageView.URL = url;
    imageView.darkModeURL = darkModeURL;
    
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
    
    if (content.images == nil) {
        return;
    }
    
    if (content.images.count == 1) {
        // add this as a single image instead of a gallery
        [self addImage:content.images.firstObject];
        return;
    }
    
    if (_last == nil || (_last && ![_last isKindOfClass:Linebreak.class])) {
        [self addLinebreak];
    }
    
    Gallery *gallery = [[Gallery alloc] initWithNib];
    gallery.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200.f);
    
    gallery.maxScreenHeight = self.view.bounds.size.height - (self.view.safeAreaInsets.top + self.additionalSafeAreaInsets.bottom) - 12.f - 38.f;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnImage:)];
    gallery.userInteractionEnabled = YES;
    
    [gallery addGestureRecognizer:tap];
    
    [self.stackView addArrangedSubview:gallery];
    // set images after adding it to the superview since -[Gallery setImages:] triggers layout.
    gallery.images = content.images;
    
    [self.images addPointer:(__bridge void *)gallery];
    gallery.idx = self.images.count - 1;
    
    _last = gallery;
    
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
                    NSMutableArray <ContentRange *> *ranges = content.ranges.mutableCopy;
                    
                    ContentRange *newRange = [ContentRange new];
                    newRange.element = @"anchor";
                    newRange.nsRange = NSMakeRange(0, content.content.length);
                    newRange.url = [NSURL URLWithString:[content.attributes valueForKey:@"href"]];
                    
                    [ranges addObject:newRange];
                    
                    content.ranges = ranges.copy;
                    rangeAdded = YES;
                }
                else if (content.url) {
                    NSMutableArray <ContentRange *> *ranges = content.ranges.mutableCopy;
                    
                    ContentRange *newRange = [ContentRange new];
                    newRange.element = @"anchor";
                    newRange.nsRange = NSMakeRange(0, content.content.length);
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
            [self processContent:item index:0 imagesFromEnclosures:@[]];
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
    
    NSString *videoID = [[content url] query];
    
    if ([videoID containsString:@"v="] == YES) {
        videoID = [videoID stringByReplacingOccurrencesOfString:@"v=" withString:@""];
    }
    
    NSLogDebug(@"Extracting YT info for: %@", videoID);
    
    if ([_last isKindOfClass:Linebreak.class] == NO) {
        [self addLinebreak];
    }
    
    AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
    playerController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerController.updatesNowPlayingInfoCenter = NO;
    playerController.showsTimecodes = YES;
    playerController.allowsPictureInPicturePlayback = YES;
        
    [self addChildViewController:playerController];
    
    UIView *playerView = playerController.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [playerView.heightAnchor constraintEqualToAnchor:playerView.widthAnchor multiplier:(9.f/16.f)].active = YES;
    
    [self.stackView addArrangedSubview:playerView];
    [playerController didMoveToParentViewController:self];
    
    [self.videos addPointer:(__bridge void *)playerController];
    
    _last = playerView;
    
    [self addLinebreak];
    
    if (self.ytExtractor == nil) {
        self.ytExtractor = [[YTExtractor alloc] init];
    }
    
    [self.ytExtractor extract:videoID success:^(VideoInfo * _Nonnull videoInfo) {
        
        if (videoInfo) {
            
            YTPlayer *player = [YTPlayer playerWithURL:videoInfo.url];
            playerController.player = player;
            
            player.playerViewController = playerController;
            
            if (videoInfo.coverImage) {

                UIImageView *imageView = [[UIImageView alloc] initWithFrame:playerController.contentOverlayView.bounds];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
//                imageView.autoUpdateFrameOrConstraints = NO;
                imageView.translatesAutoresizingMaskIntoConstraints = NO;

                [playerController.contentOverlayView addSubview:imageView];
                
                imageView.layer.masksToBounds = YES;

                [imageView.widthAnchor constraintEqualToAnchor:playerController.contentOverlayView.widthAnchor multiplier:1.f].active = YES;
                [imageView.heightAnchor constraintEqualToAnchor:playerController.contentOverlayView.heightAnchor multiplier:1.f].active = YES;
                [imageView.leadingAnchor constraintEqualToAnchor:playerController.contentOverlayView.leadingAnchor].active = YES;
                [imageView.topAnchor constraintEqualToAnchor:playerController.contentOverlayView.topAnchor].active = YES;

                NSString *thumbnail = videoInfo.coverImage;
                
                if (thumbnail == nil || [thumbnail isBlank] == YES) {}
                else {
                    
                    if (SharedPrefs.imageProxy == YES) {
                        thumbnail = [thumbnail pathForImageProxy:NO maxWidth:playerController.view.bounds.size.width quality:0.9];
                    }
                    
                    NSLog(@"Loading thumbnail for youtube video %@", videoID);
                    
                    [imageView sd_setImageWithURL:[NSURL URLWithString:thumbnail] placeholderImage:nil options:SDWebImageScaleDownLargeImages completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                        
                        if (error != nil) {
                            
                            NSLog(@"Video player failed to set image: %@\nError:%@", videoInfo.coverImage, error.localizedDescription);
                            
                            return;
                            
                        }
                        
                        NSLog(@"Video player image has been set: %@", imageURL);
                        
                    }];
                    
                }

            }
            
        }
        else {
            [self.stackView removeArrangedSubview:playerView];
            [playerView removeFromSuperview];
            
            [self _addYoutube:content];
        }
        
    } error:^(NSError * _Nonnull error) {
       
        NSLog(@"Error extracting Youtube Video info: %@", error.localizedDescription);
        
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
    youtube.URL = content.url;
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
    
//    [youtube.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:LayoutPadding].active = YES;
    
    [self addLinebreak];
}

- (void)addPre:(Content *)content {
    
    /**
     * We make a pretty gross assumption here
     * that all code blocks have atleast one tab
     * or two spaces (accounts for 4 spaces as well) 
     * in them for formatting purposes. Our convertor
     * preserves these tabs for preformatted blocks.
     */
    if (content.content != nil
        && ([content.content rangeOfString:@"\\t" options:NSRegularExpressionSearch].location == NSNotFound
            && [content.content rangeOfString:@"  " options:NSRegularExpressionSearch].location == NSNotFound
            && [content.content rangeOfString:@"\\n" options:NSRegularExpressionSearch].location == NSNotFound)) {
        
        [self addQuote:content];
        return;
        
    }
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    Code *code = [[Code alloc] initWithFrame:frame];
    code.backgroundColor = CodeParser.sharedCodeParser.theme.backgroundColor;
    
    if (content.content) {
        code.attributedText = [CodeParser.sharedCodeParser parse:content.content];
    }
    else {
        for (Content *item in content.items) { @autoreleasepool {
            [self processContent:item index:0 imagesFromEnclosures:@[]];
        } }
    }
    
    [self.stackView addArrangedSubview:code];
    
    _last = code;
    
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
    playerController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerController.updatesNowPlayingInfoCenter = NO;
    playerController.showsTimecodes = YES;
    playerController.allowsPictureInPicturePlayback = YES;
    
#if TARGET_OS_MACCATALYST
    playerController.showsPlaybackControls = NO;
#endif
    
    playerController.player = [AVPlayer playerWithURL:content.url];
    
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

- (void)didUpdateNavBarAppearance:(UIPanGestureRecognizer *)sender {
    
    if (self.helperView == nil) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        [self.helperView layoutIfNeeded];
        
        if (self.navigationController.isNavigationBarHidden == YES) {
            self.helperView.bottomConstraint.constant = -32.f + 120.f;
        }
        else {
            self.helperView.bottomConstraint.constant = -32.f;
        }
        
        [UIView animateWithDuration:1 animations:^{
           
            [self.helperView layoutIfNeeded];
            
        }];
        
    }
    
}

- (void)didTapOnBlogLabel:(UITapGestureRecognizer *)sender {
    
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    Feed *feed = [self.coordinator feedFor:((Article *)(self.item)).feedID];

    if (feed == nil) {

        [(UILabel *)sender.view setTextColor:UIColor.secondaryLabelColor];
        [sender.view removeGestureRecognizer:sender];

        return;
    }

    [self.coordinator showFeedVC:feed];
    
}

- (void)didTapRefetchArticle {
    
    self.state = ArticleVCStateLoading;
    
    weakify(self);
    
    [self.coordinator getArticle:((Article *)self.item).identifier feedID:((Article *)self.item).feedID reload:true completion:^(NSError * _Nullable error, Article * _Nullable article) {
        
        strongify(self);
       
        if (error != nil) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Reloading" message:error.localizedDescription];
            self.state = ArticleVCStateLoaded;
            return;
            
        }
        
        if (article == nil) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Reloading" message:@"No article received after reloading."];
            self.state = ArticleVCStateLoaded;
            return;
            
        }
        
        Article *item = (Article *)[self item];
        
        item.content = article.content;
        item.coverImage = article.coverImage;
        item.title = article.title;
        
        [self _setupArticle:self.item start:[NSDate date] isChangingArticle:NO];
        
    }];
    
}

#pragma mark - <ArticleAuthorViewDelegate>

- (void)didTapMercurialButton:(id)sender completion:(void (^)(BOOL))completionHandler {
    
    if (self.item == nil || ((Article *)(self.item)).identifier == nil) {
        
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
    
    // if the article already has a mercury source
    // so we swap back to the normal content
    
    if (((Article *)(self.item)).fulltext == YES) {

        NSArray <Content *> *content = [self.coordinator getContentFromDB:((Article *)(self.item)).identifier];

        if (content != nil) {

            runOnMainQueueWithoutDeadlocking(^{

                ((Article *)(self.item)).content = content;
                ((Article *)(self.item)).fulltext = NO;

                [self setupArticle:self.item];

            });

            if (completionHandler) {
                completionHandler(YES);
            }

        }
        else {

            if (completionHandler) {
                completionHandler(NO);
            }

        }

        return;
    }
    
    weakify(self);
    
    [self.coordinator getFullText:self.item completion:^(NSError * _Nullable error, Article * _Nullable responseObject) {
        
        if (error != nil) {
            completionHandler(NO);
            [AlertManager showGenericAlertWithTitle:@"An Unexpected Error Occurred" message:error.localizedDescription fromVC:self];
            return;
        }
        
        strongify(self);
        
        ((Article *)(self.item)).fulltext = responseObject.fulltext;
        ((Article *)(self.item)).read = responseObject.read;
        ((Article *)(self.item)).bookmarked = responseObject.bookmarked;

        if (responseObject.content && responseObject.content.count) {

            ((Article *)(self.item)).content = responseObject.content;

        }

        if (responseObject.coverImage) {
            ((Article *)(self.item)).coverImage = responseObject.coverImage;
        }

        if (responseObject.enclosures && responseObject.enclosures.count) {
            ((Article *)(self.item)).enclosures = responseObject.enclosures;
        }

        [self setupArticle:self.item];

        if (completionHandler) {
            completionHandler(YES);
        }
        
    }];

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
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
        
        CGRect imageFrame = imageview.frame;
        
        if (imageFrame.origin.y > 120.f) {
            imageFrame.origin.y -= 120.f;
            imageFrame.size.height += 120.f;
        }
        
        BOOL contains = CGRectContainsRect(visibleRect, imageFrame) || CGRectIntersectsRect(visibleRect, imageFrame);
        
        // the first image may be out of bounds of the scrollView when it's loaded.
        // check if it's frame is contained within the frame of the scrollView.
        
        if (imageview.idx == 0) {
            imageFrame.origin.x = 0.f;
            contains = contains || CGRectContainsRect(visibleRect, imageFrame);
        }
        
//        NSLogDebug(@"Frame:%@, contains: %@", NSStringFromCGRect(imageview.frame), @(contains));
        
        if ([imageview isMemberOfClass:Gallery.class]) {
            [(Gallery *)imageview setLoading:YES];
        }
        else if (!imageview.imageView.image && contains && !imageview.isLoading) {
//            NSLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            if (imageview.URL && [imageview.URL.absoluteString isBlank] == NO) {
                
                imageview.loading = YES;
                
                if (imageview.darkModeURL != nil && self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    [imageview setImageWithURL:imageview.darkModeURL];
                }
                else {
                    [imageview setImageWithURL:imageview.URL];
                }
                
            }
            
        }
        else if (imageview.imageView.image && !contains) {
            
            if (imageview.isLoading) {
                [imageview cancelImageLoading];
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
    
    if (enableTop != _helperView.startOfArticle.isEnabled) {
        _helperView.startOfArticle.enabled = enableTop;
    }
    
    BOOL enableBottom = y < (scrollView.contentSize.height - scrollView.bounds.size.height);
    
    if (enableBottom != _helperView.endOfArticle.isEnabled) {
        _helperView.endOfArticle.enabled = enableBottom;
    }
    
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
    
    NSLogDebug(@"Looking up anchor %@", identifier);
    
    NSArray <Paragraph *> *paragraphs = [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return [obj isKindOfClass:Paragraph.class];
    }];
    
    __block Paragraph *required = nil;
    
    Feed *feed = [self.coordinator feedFor:((Article *)(self.item)).feedID];

    NSString *base = @"";

    if (feed != nil && feed.extra != nil && feed.extra.url != nil) {

        base = feed.extra.url.absoluteString;

        if ([[base substringFromIndex:base.length - 1] isEqualToString:@"/"]) {
            base = [base substringToIndex:base.length-1];
        }

    }
    
    for (Paragraph *para in paragraphs) { @autoreleasepool {
        
//        NSAttributedString *attrs = para.attributedText;
//
//        [attrs enumerateAttribute:NSLinkAttributeName inRange:NSMakeRange(0, attrs.length) options:NSAttributedStringEnumerationReverse usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        
        [para.links enumerateObjectsUsingBlock:^(Link * _Nonnull obj, BOOL * _Nonnull stop) {
            
            id value = obj.url;
            
            if (value) {
                
                NSString *compare = value;
                
                if ([value isKindOfClass:NSURL.class]) {
                    compare = [(NSURL *)value absoluteString];
                }
                
                compare = [compare stringByReplacingOccurrencesOfString:@"#" withString:@""];
                 
                if (base.length > 0 && [compare containsString:base]) {
                    compare = [compare stringByReplacingOccurrencesOfString:base withString:@""];
                }
                
                float ld = [identifier compareStringWithString:compare];
                NSLogDebug(@"href:%@ distance:%@", compare, @(ld));
                
                BOOL contained = [compare containsString:identifier] || [identifier containsString:compare];
                
                NSLogDebug(@"sub matching:%@", contained ? @"Yes" : @"No");
                
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
        
//        NSLogDebug(@"Found the paragraph: %@", required);
        
        self.scrollView.userInteractionEnabled = NO;
        // compare against the maximum contentOffset which is contentsize.height - bounds.size.height
        CGFloat yOffset = MIN(frame.origin.y - 160, (self.scrollView.contentSize.height - self.scrollView.bounds.size.height));
        
        // if we're scrolling down, add the bottom offset so the bottom bar does not interfere
        if (yOffset > self.scrollView.contentOffset.y) {
            yOffset += self.scrollView.adjustedContentInset.bottom;
            yOffset += CGRectGetMidY(required.bounds);
        }
        else {
            yOffset += self.scrollView.adjustedContentInset.top;
        }
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
            self.scrollView.userInteractionEnabled = NO;
        });
        
        weakify(required);
        
        // animate background on paragraph
        
        required.layer.cornerRadius = 4.f;
        
        NSTimeInterval animationDuration = 0.3;
        
        [UIView animateWithDuration:animationDuration delay:1 options:kNilOptions animations:^{
            
            strongify(required);
            
            required.backgroundColor = [UIColor.systemYellowColor colorWithAlphaComponent:0.3f];
            
            strongify(self);
            self.scrollView.userInteractionEnabled = YES;
            
        } completion:^(BOOL finished) { dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(required);
            
            if (finished) {
                
                [UIView animateWithDuration:animationDuration delay:1.5 options:kNilOptions animations:^{
                    
                    required.backgroundColor = UIColor.systemBackgroundColor;
                    
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
    if (yOffset > (self.scrollView.contentSize.height - self.scrollView.contentOffset.y))
        yOffset += self.scrollView.adjustedContentInset.bottom;
//    else
//        yOffset -= self.scrollView.adjustedContentInset.top;
    
//    yOffset += (self.scrollView.bounds.size.height / 2.f);
    
    [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
    
    weakify(self);
    
    asyncMain(^{
        strongify(self);
        self.scrollView.userInteractionEnabled = YES;
    });
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    
    if (interaction != UITextItemInteractionInvokeDefaultAction) {
        return YES;
    }
    
    NSString *originalURL = [URL absoluteString];
    
    if (URL.host == nil) {
        // absolute link in the article. Resovle to fully qualified URL
        NSURLComponents *articleComp = [NSURLComponents componentsWithString:[((Article *)(self.item)).url absoluteString]];
        NSURLComponents *urlComp = [NSURLComponents componentsWithString:URL.absoluteString];
        
        urlComp.host = articleComp.host;
        urlComp.scheme = articleComp.scheme;
        urlComp.path = articleComp.path;
        URL = [urlComp URL];
    }
    
    NSString *absolute = URL.absoluteString;
    
    NSLogDebug(@"Interact with URL: %@ and interaction type: %@", URL, @(interaction));
    
    if (interaction != UITextItemInteractionPresentActions) {
        // footlinks and the like
        
        if (originalURL && (originalURL.length > 0 && [[originalURL substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"])) {
            [self scrollToIdentifer:originalURL];
            return NO;
        }
        
        if ((absolute && (absolute.length > 0) && [[absolute substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"])) {
            [self scrollToIdentifer:absolute];
            return NO;
        }
        
        Feed *feed = [self.coordinator feedFor:((Article *)(self.item)).feedID];
        
        NSString *base = @"";
        
        if (feed != nil && feed.extra != nil && feed.extra.url != nil) {
            base = feed.extra.url.absoluteString;
        }

        if ([absolute containsString:@"#"] &&
            ([absolute containsString:base] || ([absolute compareStringWithString:base] <= base.length))
            ) {

            NSUInteger location = [absolute rangeOfString:@"#"].location;

            absolute = [absolute substringFromIndex:location];

            [self scrollToIdentifer:absolute];
            return NO;

        }
        
        // links to sections within the article
        if ([absolute containsString:((Article *)(self.item)).url.absoluteString] && ![absolute isEqualToString:((Article *)(self.item)).url.absoluteString]) {
            // get the section ID
            NSRange range = [absolute rangeOfString:@"#"];
            
            NSString *identifier = [absolute substringFromIndex:range.location];
            
            BOOL retval = [self scrollToHeading:identifier];
            
            if (!retval)
                return retval;
        }
        else {
            
            // open the link externally since it's not available in headings
            // or the link appears to be different from the article's URL.
            [self openLinkExternally:absolute];
            
            return NO;
            
        }
    }
    
    if (interaction == UITextItemInteractionPresentActions) {
        NSString * const linkedHeader = @"🔗 ";
        
        NSString *text = [textView.attributedText.string substringWithRange:characterRange];
        
        if ([text isEqualToString:linkedHeader]) {
            text = [[textView text] stringByReplacingOccurrencesOfString:linkedHeader withString:@""];
            
            NSString *articleTitle = (((Article *)(self.item)).title && ![((Article *)(self.item)).title isBlank]) ? formattedString(@"- %@", ((Article *)(self.item)).title) : @"";
            text = formattedString(@"%@%@", text, articleTitle);
        }
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:nil];
        
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            
            UIPopoverPresentationController *pvc = [avc popoverPresentationController];
            pvc.sourceView = textView;
            pvc.sourceRect = [Paragraph boundingRectIn:textView forCharacterRange:characterRange];
            
            NSLogDebug(@"view: %@", pvc.sourceView);
        }
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    else {
        
        [self openLinkExternally:absolute];
        
    }
    
    return NO;
}

- (void)openLinkExternally:(NSString *)link {
    
    if (link == nil || [link isBlank]) {
        return;
    }
    
    NSURL *formatted;
    
    if ([link containsString:@"/feed"]) {
        
        // handle internally
        formatted = formattedURL(@"yeti://addFeedConfirm?URL=%@", [link encodeURIComponents]);
        
    }
    else {
        formatted = formattedURL(@"yeti://external?link=%@", [link encodeURIComponents]);
    }
    
#if TARGET_OS_MACCATALYST
    
    if (_shiftPressedBeforeClickingURL) {
        
        formatted = formattedURL(@"%@&shift=1", formatted.absoluteString);
        
    }
    
#endif
    
    runOnMainQueueWithoutDeadlocking(^{
        
        [[UIApplication sharedApplication] openURL:formatted options:@{} completionHandler:nil];
        
    });
    
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

- (NSUInteger)boundingRangeIn:(UITextView *)textView forPoint:(CGPoint)point {
    
    NSTextStorage *textStorage = [textView textStorage];
    NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
    NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];
    
    CGFloat fractionalDistance = 0.f;
    
    NSUInteger index = [layoutManager characterIndexForPoint:point inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:&fractionalDistance];
    
    return index;
    
}

#pragma mark - Presses

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    
    UIPress *press = presses.anyObject;
    
    if (press.key.keyCode == UIKeyboardHIDUsageKeyboardEscape) {
        
        if (press.responder != nil && [press.responder isKindOfClass:NSClassFromString(@"UISearchBarTextField")]) {
            
            [self didTapSearchDone];
            
        }
        
    }
#if TARGET_OS_MACCATALYST
    else if (press.key.modifierFlags == UIKeyModifierShift && _shiftPressedBeforeClickingURL == NO) {
        
        self->_shiftPressedBeforeClickingURL = YES;
        
        /*
         * Reset this value back to NO so the next event can be reliably detected.
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            self->_shiftPressedBeforeClickingURL = NO;
            
        });
        
    }
#endif
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardDownArrow) {
        
        if (press.key.modifierFlags == UIKeyModifierShift) {
            [self scrollToEnd];
        }
        else {
            [self scrollDown];
        }
        
    }
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardUpArrow) {
        
        if (press.key.modifierFlags == UIKeyModifierShift) {
            [self scrollToTop];
        }
        else {
            [self scrollUp];
        }
        
    }
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardLeftArrow) {
        [self navLeft];
    }
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardRightArrow) {
        [self navRight];
    }
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardJ && self.providerDelegate != nil) {
        
        [self didTapPreviousArticle:nil];
        
    }
    else if (press.key.keyCode == UIKeyboardHIDUsageKeyboardK && self.providerDelegate != nil) {
        
        [self didTapNextArticle:nil];
        
    }
    else {
        
        NSLogDebug(@"Presses: %@\n Events:%@", presses, event);
        
        [super pressesBegan:presses withEvent:event];
        
    }
    
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
    if (_searchView == nil) {
        
        CGFloat heightReducer = 0.f;
        
#if TARGET_OS_MACCATALYST
        heightReducer = 12.f;
#endif
        
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 52.f - heightReducer);
        
#if TARGET_OS_MACCATALYST
        frame.origin.y = 36.f;
#endif
        
        UIInputView * searchView = [[UIInputView alloc] initWithFrame:frame];
#if TARGET_OS_MACCATALYST
//        [searchView setValue:@(UIInputViewStyleDefault) forKeyPath:@"inputViewStyle"];
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        
        searchView.backgroundColor = UIColor.clearColor;
        effectView.frame = searchView.bounds;
        
        [searchView addSubview:effectView];
#else
        [searchView setValue:@(UIInputViewStyleKeyboard) forKeyPath:@"inputViewStyle"];
#endif
        searchView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        CGFloat borderHeight = 1/[[UIScreen mainScreen] scale];
        
        frame = CGRectMake(0, 0, frame.size.width, borderHeight);
        
#if TARGET_OS_MACCATALYST
        frame.origin.y = frame.size.height - borderHeight;
#endif
        
        UIView *border = [[UIView alloc] initWithFrame:frame];
        border.backgroundColor = UIColor.separatorColor;
        border.translatesAutoresizingMaskIntoConstraints = NO;
        [border.heightAnchor constraintEqualToConstant:borderHeight].active = YES;
        
        [searchView addSubview:border];
#if TARGET_OS_MACCATALYST
        [border.bottomAnchor constraintEqualToAnchor:searchView.bottomAnchor constant:-borderHeight].active = YES;
#else
        [border.topAnchor constraintEqualToAnchor:searchView.topAnchor].active = YES;
#endif
        
        [border.widthAnchor constraintEqualToAnchor:searchView.widthAnchor].active = YES;
        
        UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
        [prev setImage:[UIImage systemImageNamed:@"chevron.up"] forState:UIControlStateNormal];
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
        [next setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
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
        
        frame.size.height = 52.f - heightReducer;
        frame.size.width = self.view.bounds.size.width;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(64.f, 8.f, frame.size.width - 64.f - CGRectGetWidth(done.frame) - 8.f, frame.size.height - 16.f)];
        searchBar.searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.placeholder = @"Search Article";
        searchBar.keyboardType = UIKeyboardTypeDefault;
        searchBar.returnKeyType = UIReturnKeySearch;
        searchBar.delegate = self;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UITextField *searchField = [searchBar valueForKeyPath:@"searchField"];
        if (searchField) {
            searchField.textColor = UIColor.labelColor;
        }
        
        searchBar.backgroundColor = UIColor.clearColor;
        searchBar.backgroundImage = nil;
        searchBar.scopeBarBackgroundImage = nil;
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.translucent = NO;
        searchBar.accessibilityHint = @"Search for keywords in the article";
        
        [searchView addSubview:searchBar];
        self.searchBar = searchBar;
        
        [searchBar.heightAnchor constraintEqualToConstant:frame.size.height - 16.f].active = YES;
        
        self.searchPrevButton = prev;
        self.searchNextButton = next;
        
        UIColor *tint = self.view.tintColor;
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

//NSString * const kArticleData = @"ArticleData";
//NSString * const kScrollViewSize = @"ScrollViewContentSize";
//NSString * const kScrollViewOffset = @"ScrollViewOffset";

//- (void)continueActivity:(NSUserActivity *)activity {
//
//    NSDictionary *article = [activity.userInfo valueForKey:@"article"];
//
//    if (article == nil) {
//        return;
//    }
//
////    CGSize size = CGSizeFromString([article valueForKey:kScrollViewSize]);
//    CGPoint offset = CGPointFromString([article valueForKey:kScrollViewOffset]);
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.scrollView setContentOffset:offset animated:NO];
//    });
//
//}
//
//- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity {
//
//    NSString *contentSize = NSStringFromCGSize(self.scrollView.contentSize);
//    NSString *contentOffset = NSStringFromCGPoint(self.scrollView.contentOffset);
//
//    [activity addUserInfoEntriesFromDictionary:@{@"article": @{
//                                                         kScrollViewSize: contentSize,
//                                                         kScrollViewOffset: contentOffset
//    }
//    }];
//
//}
//
//+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
//
//    Article *item = [coder decodeObjectForKey:kArticleData];
//
//    if (item != nil) {
//        ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
//        return vc;
//    }
//
//    return nil;
//
//}
//
//- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//
//    NSLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
//
//    [super encodeRestorableStateWithCoder:coder];
//
//    [coder encodeObject:self.item forKey:kArticleData];
//    [coder encodeCGSize:self.scrollView.contentSize forKey:kScrollViewSize];
//    [coder encodeCGPoint:self.scrollView.contentOffset forKey:kScrollViewOffset];
//}
//
//- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
//
//    NSLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
//
//    [super decodeRestorableStateWithCoder:coder];
//
//    Article * item = [coder decodeObjectForKey:kArticleData];
//
//    if (item) {
//        _isRestoring = YES;
//
//        [self setupArticle:item];
//
//        weakify(self);
//
//        CGSize size = [coder decodeCGSizeForKey:kScrollViewSize];
//        CGPoint offset = [coder decodeCGPointForKey:kScrollViewOffset];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            strongify(self);
//
//            self.scrollView.contentSize = size;
//            [self.scrollView setContentOffset:offset animated:NO];
//        });
//    }
//}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([object isKindOfClass:AVPlayer.class] && [keyPath isEqualToString:propSel(rate)]) {
        
        [object removeObserver:self forKeyPath:propSel(rate) context:KVO_PlayerRate];
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

#pragma mark - <UIPointerInteractionDelegate>

- (void)pointerInteraction:(UIPointerInteraction *)interaction willEnterRegion:(UIPointerRegion *)region animator:(id<UIPointerInteractionAnimating>)animator  API_AVAILABLE(ios(13.4)) {
    
    if ([interaction.view isKindOfClass:UILabel.class] == YES) {
        interaction.view.backgroundColor = UIColor.clearColor;
    }
    
}

- (void)pointerInteraction:(UIPointerInteraction *)interaction willExitRegion:(UIPointerRegion *)region animator:(id<UIPointerInteractionAnimating>)animator API_AVAILABLE(ios(13.4)) {
    
    if ([interaction.view isKindOfClass:UILabel.class] == YES) {
        interaction.view.backgroundColor = UIColor.clearColor;
    }
    
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region  API_AVAILABLE(ios(13.4)){
    
    UIPreviewParameters *params = [UIPreviewParameters new];
    
    CGRect bounds = interaction.view.bounds;
    
    if ([interaction.view isKindOfClass:UILabel.class] == YES) {
        
        UILabel *label = (UILabel *)[interaction view];
        
        CGSize textBounds = [label sizeThatFits:bounds.size];

        NSLogDebug(@"textBounds: %@\nBounds: %@", [NSValue valueWithCGSize:textBounds], [NSValue valueWithCGRect:bounds]);

        bounds.size = textBounds;
        
        // inset it so we get some padding.
        // Typically around 4px
        // CGRectInset produces a weird behavior here.
        bounds.origin.x -= 2.f;
        bounds.origin.y -= 2.f;
        bounds.size.width += 16.f;
        bounds.size.height += 4.f;
    }
    
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:4.f];
    
    UIPointerShape *shape = [UIPointerShape shapeWithPath:params.visiblePath];
    
    UITargetedPreview *preview = [[UITargetedPreview alloc] initWithView:interaction.view parameters:params];
    
    UIPointerStyle *style = [UIPointerStyle styleWithEffect:[UIPointerHighlightEffect effectWithPreview:preview] shape:shape];
    
    return style;
    
    /*
    let params = UIPreviewParameters()
    params.visiblePath = starView.starPath
    
    let preview = UITargetedPreview(view: starView, parameters: params)

    return UIPointerStyle(effect: .automatic(preview), shape: .path(starView.starPath))
    */
}

#pragma mark - <TextSharing>

- (void)shareText:(NSString *)text paragraph:(Paragraph *)paragraph rect:(CGRect)rect {
    
    text = formattedString(@"\"%@\"", text);
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[text, ((Article *)(self.item)).url] applicationActivities:nil];
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        pvc.sourceView = paragraph;
        pvc.sourceRect = rect;
        
    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

#pragma mark - <UIContextMenuInteractionDelegate>

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    
    if ([interaction.view isKindOfClass:Heading.class]) {
        
        // check if NSURL exists
        Heading *view = (Heading *)[interaction view];
        
        NSUInteger index = [self boundingRangeIn:view forPoint:location];
        
        if (index == 0) {
            
            // check range for link
            NSRange range = NSMakeRange(index, 2);
            NSRange longest = NSMakeRange(index, 2);
            
            NSURL *url = [view.attributedText attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&longest inRange:range];
            
            if (url != nil) {
                
                return [self contextConfigForSharingURL:url from:view];
                
            }
            
        }
        
    }
    
    return nil;
    
}

- (UIContextMenuConfiguration *)contextConfigForSharingURL:(NSURL *)url from:(UIView *)view {
    
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:url previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        
        UIAction *share = [UIAction actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
            
            if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
                
                UIPopoverPresentationController *pvc = avc.popoverPresentationController;
                pvc.sourceView = view;
                pvc.sourceRect = view.frame;
                
            }
            
            [self presentViewController:avc animated:YES completion:nil];
            
        }];
        
        UIAction *copy = [UIAction actionWithTitle:@"Copy Link" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            UIPasteboard.generalPasteboard.URL = url;
            
        }];
        
        UIMenu *menu = [UIMenu menuWithChildren:@[share, copy]];
        
        return menu;
        
    }];
    
    return config;
    
}

@end
