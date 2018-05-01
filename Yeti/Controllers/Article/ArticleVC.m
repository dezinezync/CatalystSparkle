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

#import <SafariServices/SafariServices.h>

#import "ArticleHelperView.h"

@interface ArticleVC () <UIScrollViewDelegate, UITextViewDelegate> {
    BOOL _hasRendered;
    
    BOOL _isQuoted;
    
    BOOL _deferredProcessing;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottom;
@property (weak, nonatomic) UIView *last; // reference to the last setup view.
@property (weak, nonatomic) id nextItem; // next item which will be processed
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;
@property (nonatomic, strong) NSPointerArray *images;

@property (nonatomic, strong) CodeParser *codeParser;
@property (nonatomic, weak) ArticleHelperView *helperView;

@end

@implementation ArticleVC

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (instancetype)initWithItem:(FeedItem *)item
{
    if (self = [super initWithNibName:NSStringFromClass(ArticleVC.class) bundle:nil]) {
        self.item = item;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(0.f, 0.f, 44.f, 0.f);
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        || self.splitViewController.view.bounds.size.height < 814.f) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 88.f, 0);
        
        self.scrollView.contentInset = UIEdgeInsetsMake(LayoutPadding * 2, 0, 0, 0);
    }
    
    UILayoutGuide *readable = self.scrollView.readableContentGuide;
    
   [self setupHelperView];
    
    [self.stackView.leadingAnchor constraintEqualToAnchor:readable.leadingAnchor constant:LayoutPadding/2.f].active = YES;
    [self.stackView.trailingAnchor constraintEqualToAnchor:readable.trailingAnchor constant:-LayoutPadding/2.f].active = YES;
    
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    weakify(self);
    
    [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        strongify(self);
        [self.stackView removeArrangedSubview:obj];
        [obj removeFromSuperview];
        
    }];
    
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView layoutIfNeeded];
    
    [self.stackView setNeedsUpdateConstraints];
    [self.stackView layoutIfNeeded];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardDidHideNotification object:nil];
    [center addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    if (!_hasRendered) {
        [self.loader startAnimating];
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_hasRendered)
        return;
    
    _hasRendered = YES;
    
    [self setupArticle:self.item];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [self.navigationController popViewControllerAnimated:NO];
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

- (void)setupHelperView {
    
    if (self.providerDelegate == nil)
        return;
    
    ArticleHelperView *helperView = [[ArticleHelperView alloc] initWithNib];
    helperView.frame = CGRectMake((self.view.bounds.size.width - 190.f) / 2.f, self.view.bounds.size.height - 44.f - 32.f, 190.f, 44.f);
    
    [self.view addSubview:helperView];
    
    [helperView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [helperView.widthAnchor constraintEqualToConstant:190.f].active = YES;
    [helperView.heightAnchor constraintEqualToConstant:44.f].active = YES;
    helperView.bottomConstraint = [helperView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-32.f];
    helperView.bottomConstraint.active = YES;
    
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

- (void)didChangePreferredContentSize:(NSNotification *)note {
    
    [self setupArticle:self.currentArticle];
    
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    weakify(self);
    
    if (coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
            strongify(self);
            
            [self setupToolbar:newCollection];
            
        } completion:nil];
    }
    else
        [self setupToolbar:newCollection];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (CGSizeEqualToSize(self.view.bounds.size, size))
        return;

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

        for (Image *imageView in self.images) { @autoreleasepool {
            if ([imageView respondsToSelector:@selector(imageView)] && imageView.imageView.image) {
                [imageView.imageView updateAspectRatioWithImage:imageView.imageView.image];
            }
            else if ([imageView respondsToSelector:@selector(image)] && [(UIImageView *)imageView image]) {
                [(SizedImage *)imageView updateAspectRatioWithImage:[(UIImageView *)imageView image]];
            }
        } }

    } completion:nil];
}

#pragma mark - <ArticleHandler>

- (FeedItem *)currentArticle
{
    return self.item;
}

- (void)setupArticle:(FeedItem *)article
{
    if (!article)
        return;
    
    BOOL isChangingArticle = self.item && self.item.identifier.integerValue != article.identifier.integerValue;
    
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
    
    self.item = article;
    
    self.images = [NSPointerArray weakObjectsPointerArray];
    [self setupToolbar:self.traitCollection];
    
#ifdef DEBUG
    NSDate *start = NSDate.date;
#endif
    
    self.stackView.hidden = YES;
    
    // add Body
    [self addTitle];
    
    if (self.item.content.count > 15) {
        _deferredProcessing = YES;
    }
    
    for (Content *content in self.item.content) { @autoreleasepool {
        [self processContent:content];
    } }
    
    [self.loader stopAnimating];
    [self.loader removeFromSuperview];
    
    _last = nil;
    
#ifdef DEBUG
    DDLogInfo(@"Processing: %@", @([NSDate.date timeIntervalSinceDate:start]));
#endif
    
    self.stackView.hidden = NO;
    [self setupHelperViewActions];
    
    if (self.item && !self.item.isRead)
        [MyFeedsManager article:self.item markAsRead:YES];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self scrollViewDidScroll:self.scrollView];
        
        CGSize contentSize = self.scrollView.contentSize;
        contentSize.width = self.view.bounds.size.width;
        
        self.scrollView.contentSize = contentSize;
        
        DDLogDebug(@"ScrollView contentsize: %@", NSStringFromCGSize(contentSize));
    });
    
    if (isChangingArticle && self.providerDelegate) {
        [(NSObject *)(self.providerDelegate) performSelectorOnMainThread:@selector(didChangeToArticle:) withObject:article waitUntilDone:NO];
    }
}

#pragma mark - Drawing

- (void)addTitle {
    
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
    
    NSString *subline = formattedString(@"%@ • %@", author, [(NSDate *)(self.item.timestamp) timeAgoSinceDate:NSDate.date numericDates:YES numericTimes:YES]);
    
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineHeightMultiple = 1.025f;
    
    ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
    CGFloat baseFontSize = 32.f;
    
    if (self.item.articleTitle.length > 24) {
        baseFontSize = 26.f;
    }
    
    UIFont *baseFont = [fontPref isEqualToString:ALPSystem] ? [UIFont boldSystemFontOfSize:baseFontSize] : [UIFont fontWithName:@"Georgia-Bold" size:baseFontSize];
    
    UIFont * titleFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:baseFont];
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : titleFont,
                                     NSForegroundColorAttributeName: UIColor.blackColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: [fontPref isEqualToString:ALPSystem] ? @(-1.14f) : [NSNull null],
                                     };
    
    // Subline
    baseFontSize = 16.f;
    baseFont = [fontPref isEqualToString:ALPSystem] ? [UIFont systemFontOfSize:baseFontSize weight:UIFontWeightMedium] : [UIFont fontWithName:@"Georgia" size:baseFontSize];
    
    UIFont *subtextFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:baseFont];
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: subtextFont,
                                        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:0.54f],
                                        NSParagraphStyleAttributeName: para,
                                        NSKernAttributeName: [fontPref isEqualToString:ALPSystem] ? @(-0.43f) : [NSNull null]
                                        };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:self.item.articleTitle attributes:baseAttributes];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    label.numberOfLines = 0;
    label.attributedText = attrs;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.lineBreakMode = NSLineBreakByWordWrapping;
//    label.preferredMaxLayoutWidth = self.view.bounds.size.width;
    
    [label sizeToFit];
    
    label.backgroundColor = UIColor.whiteColor;
    label.opaque = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *sublabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    sublabel.numberOfLines = 0;
    sublabel.attributedText = [[NSAttributedString alloc] initWithString:subline attributes:subtextAttributes];
    sublabel.translatesAutoresizingMaskIntoConstraints = NO;
    sublabel.lineBreakMode = NSLineBreakByWordWrapping;
//    sublabel.preferredMaxLayoutWidth = self.view.bounds.size.width;
    
    [sublabel sizeToFit];
    
    sublabel.backgroundColor = UIColor.whiteColor;
    sublabel.opaque = YES;
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 48.f)];
    mainView.translatesAutoresizingMaskIntoConstraints = NO;
    [mainView addSubview:label];
    
    [label.leadingAnchor constraintEqualToAnchor:mainView.leadingAnchor].active = YES;
    [label.trailingAnchor constraintEqualToAnchor:mainView.trailingAnchor].active = YES;
    [label.topAnchor constraintEqualToAnchor:mainView.topAnchor].active = YES;
    [label setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
    [mainView addSubview:sublabel];
    
    [sublabel.leadingAnchor constraintEqualToAnchor:mainView.leadingAnchor].active = YES;
    [sublabel.trailingAnchor constraintEqualToAnchor:mainView.trailingAnchor].active = YES;
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
    if ([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingOnlyWireless]) {
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
    else if ([content.type isEqualToString:@"paragraph"] || [content.type isEqualToString:@"cite"]) {
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
    else if ([content.type isEqualToString:@"image"]) {
        [self addImage:content];
    }
    else if ([content.type isEqualToString:@"blockquote"]) {
        [self addQuote:content];
    }
    else if ([content.type containsString:@"list"]) {
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
    else if ([content.type isEqualToString:@"a"] || [content.type isEqualToString:@"anchor"]) {
        
        if (content.content && content.content.length) {
            [self addParagraph:content caption:NO];
        }
        else if (content.items) {
            for (Content *sub in content.items) { @autoreleasepool {
                
                [self processContent:sub];
                
            } }
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
    else if ([content.type isEqualToString:@"hr"]) {
        
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
        if(lastPara.isCaption && [lastPara.text isEqualToString:content.content])
            return;
    }
    
    para.caption = caption;
    
    // check if attributes has href
    if (content.attributes && [content.attributes valueForKey:@"href"]) {
        NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
        
        Range *newRange = [Range new];
        newRange.element = @"anchor";
        newRange.range = NSMakeRange(0, content.content.length);
        newRange.url = [content.attributes valueForKey:@"href"];
        
        [ranges addObject:newRange];
        
        content.ranges = ranges.copy;
    }
    else if (content.url) {
        NSMutableArray <Range *> *ranges = content.ranges.mutableCopy;
        
        Range *newRange = [Range new];
        newRange.element = @"anchor";
        newRange.range = NSMakeRange(0, content.content.length);
        newRange.url = content.url;
        
        [ranges addObject:newRange];
        
        content.ranges = ranges.copy;
    }
    
    if ([_last isMemberOfClass:Paragraph.class] && ![(Paragraph *)_last isCaption] && !para.isCaption) {
        
        // since the last one is a paragraph as well, simlpy append to it.
        Paragraph *last = (Paragraph *)_last;
        
        NSMutableAttributedString *attrs = last.attributedText.mutableCopy;
        
        NSAttributedString *newAttrs = [para processText:content.content ranges:content.ranges attributes:content.attributes];
        
        [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
        [attrs appendAttributedString:newAttrs];
        
        last.attributedText = attrs.copy;
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
        heading.identifier = content.identifier;
        
        NSAttributedString *attrs = heading.attributedText;
        
        NSURL *url = formattedURL(@"%@#%@", self.item.articleURL, content.identifier);
        
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
    if (_last && [NSStringFromClass(_last.class) isEqualToString:@"UIView"])
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

    _last = linebreak;
    
    [self.stackView addArrangedSubview:linebreak];
}

- (void)addImage:(Content *)content {
    
    if (![self showImage])
        return;
    
    if ([_last isMemberOfClass:Heading.class] || !_last || [_last isMemberOfClass:Paragraph.class])
        [self addLinebreak];
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    CGFloat scale = content.size.height / content.size.width;
    
    Image *imageView = [[Image alloc] initWithFrame:frame];
    
    _last = imageView;
    
    // hides tracking images
    if (CGSizeEqualToSize(content.size, CGSizeZero) == NO && content.size.width == 1.f && content.size.height == 1.f) {
        imageView.hidden = YES;
    }
    
    [self.stackView addArrangedSubview:imageView];
    
    if (!CGSizeEqualToSize(content.size, CGSizeZero) && scale != NAN) {
        imageView.aspectRatio = [imageView.heightAnchor constraintEqualToAnchor:imageView.widthAnchor multiplier:scale];
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
        
        imageView.accessibilityValue = content.alt ?: [content.attributes valueForKey:@"alt"];
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
    
    if ([_last isMemberOfClass:Heading.class]) {
        [self addLinebreak];
    }
    
    Gallery *gallery = [[Gallery alloc] initWithNib];
    gallery.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200.f);
    
    [self.stackView addArrangedSubview:gallery];
    // set images after adding it to the superview since -[Gallery setImages:] triggers layout.
    gallery.images = content.images;
    
    [self.images addPointer:(__bridge void *)gallery];
    gallery.idx = self.images.count - 1;
    
}

- (void)addQuote:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    
    if (!content.content && (!content.items || content.items.count == 0))
        return;
    
    Blockquote *para = [[Blockquote alloc] initWithFrame:frame];
    
    if (content.content) {
        [para setText:content.content ranges:content.ranges attributes:content.attributes];
    }
    else if (content.items) {
        
        NSMutableAttributedString *mattrs = [NSMutableAttributedString new];
        
        for (Content *item in content.items) { @autoreleasepool {
            NSAttributedString *attrs = [para processText:item.content ranges:item.ranges attributes:item.attributes];
            
            [mattrs appendAttributedString:attrs];
            [mattrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
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
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 0);
    Youtube *youtube = [[Youtube alloc] initWithFrame:frame];
    youtube.URL = [NSURL URLWithString:content.url];
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
    
//    [youtube.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

- (void)addPre:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 32.f);
    Code *code = [[Code alloc] initWithFrame:frame];
    
    if (content.content) {
        code.attributedText = [self.codeParser parse:content.content];
//        CGSize contentSize = code.para.contentSize;
        
//        frame.size.height = contentSize.height;
//        code.frame = frame;
    }
    else {
        
    }
    
    [self.stackView addArrangedSubview:code];
    
}

- (void)addTweet:(Content *)content {
    CGRect frame = CGRectMake(0, 0, MAX(self.view.bounds.size.width, 480.f), 0);
    Tweet *tweet = [[Tweet alloc] initWithNib];
    tweet.frame = frame;
    
    tweet.textview.delegate = self;
    
    [tweet configureContent:content];
    
    _last = tweet;
    
    [self.stackView addArrangedSubview:tweet];
    
//    [tweet.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

#pragma mark - Getters

// This getter is always lazily loaded from addPre:
- (CodeParser *)codeParser
{
    if (!_codeParser) {
        _codeParser = [[CodeParser alloc] init];
    }
    
    return _codeParser;
}

#pragma mark - Actions

- (void)didTapOnImageWithURL:(UITapGestureRecognizer *)sender {
    
    Image *view = (Image *)[sender view];
    NSString *url = [[view URL] absoluteString];
    
    NSURL *formatted = formattedURL(@"yeti://external?link=%@", url);
    
    [UIApplication.sharedApplication openURL:formatted options:@{} completionHandler:nil];
    
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    
    NSArray <UIView *>  * visibleViews = [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return CGRectIntersectsRect(visibleRect, CGRectOffset(obj.frame, 0, 48.f));
    }];
    
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
    
    CGPoint point = scrollView.contentOffset;
    // adding the scrollView's height here triggers loading of the image as soon as it's about to appear on screen.
    point.y += scrollView.bounds.size.height;
    
    for (Image *imageview in self.images) { @autoreleasepool {
        
        BOOL contains = CGRectContainsPoint(imageview.frame, point);
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
            DDLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageview.loading = YES;
                [imageview il_setImageWithURL:imageview.URL];
            });
        }
    } }
    
    CGFloat y = point.y - scrollView.bounds.size.height;
    
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
        
        DDLogDebug(@"Found the paragraph: %@", required);
        
        self.scrollView.userInteractionEnabled = NO;
        // compare against the maximum contentOffset which is contentsize.height - bounds.size.height
        CGFloat yOffset = MIN(frame.origin.y - 160, (self.scrollView.contentSize.height - self.scrollView.bounds.size.height));
        
        // if we're scrolling down, add the bottom offset so the bottom bar does not interfere
        if (yOffset > self.scrollView.contentOffset.y)
            yOffset += self.scrollView.adjustedContentInset.bottom;
        else
            yOffset -= self.scrollView.adjustedContentInset.top;
        
        [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
        
        // animate background on paragraph
        
        weakify(self);
        
        asyncMain(^{
            required.layer.cornerRadius = 4.f;
            [UIView animateWithDuration:0.1 delay:0.5 options:kNilOptions animations:^{
                required.backgroundColor = [UIColor colorWithRed:255/255.f green:249/255.f blue:207/255.f alpha:1.f];
                strongify(self);
                self.scrollView.userInteractionEnabled = YES;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.3 delay:1 options:kNilOptions animations:^{
                    required.backgroundColor = [UIColor whiteColor];
                } completion:^(BOOL finished) {
                    required.layer.cornerRadius = 0.f;
                    required = nil;
                }];
                
            }];
        })
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
    
    NSString *absolute = URL.absoluteString;
    
    // footlinks and the like
    if (absolute.length && [[absolute substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
        [self scrollToIdentifer:absolute];
        return NO;
    }
    
    // links to sections within the article
    if ([absolute containsString:self.item.articleURL]) {
        // get the section ID
        NSRange range = [absolute rangeOfString:@"#"];
        
        NSString *identifier = [absolute substringFromIndex:range.location];
        
        BOOL retval = [self scrollToHeading:identifier];
        
        if (!retval)
            return retval;
    }
    
    if (interaction == UITextItemInteractionPreview)
        return YES;
    
    if (interaction == UITextItemInteractionPresentActions) {
        NSString *text = [textView.attributedText.string substringWithRange:characterRange];
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[text, URL] applicationActivities:nil];
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    else {
        NSURL *formatted = formattedURL(@"yeti://external?link=%@", absolute);
        
        [[UIApplication sharedApplication] openURL:formatted options:@{} completionHandler:nil];
    }
    
    return NO;
}

@end
