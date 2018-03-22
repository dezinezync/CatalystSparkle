//
//  ArticleVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import "FeedsManager+KVS.h"
#import "NSString+Levenshtein.h"
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

#import <DZNetworking/UIImageView+ImageLoading.h>
#import "NSAttributedString+Trimming.h"
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>
#import "NSDate+DateTools.h"
#import "CodeParser.h"

#import <SafariServices/SafariServices.h>

#import "ArticleHelperView.h"

static CGFloat const baseFontSize = 16.f;

static CGFloat const padding = 6.f;

@interface ArticleVC () <UIScrollViewDelegate, UITextViewDelegate> {
    BOOL _hasRendered;
    
    BOOL _isQuoted;
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
    
    UILayoutGuide *readable = self.scrollView.readableContentGuide;
    
    CGFloat multiplier = 1.f;
    
    [self setupHelperView];
    
    [self.stackView.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:readable.leadingAnchor multiplier:multiplier].active = YES;
    [self.stackView.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:readable.trailingAnchor multiplier:multiplier].active = YES;
    
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
    
//    self.helperView.previousArticleButton.imageView.tintColor = self.helperView.previousArticleButton.isEnabled ? self.view.tintColor : [UIColor colorWithWhite:0.5 alpha:1.f];
//    [self.helperView.previousArticleButton setNeedsDisplay];
    
    [self.helperView.nextArticleButton setEnabled:next];
    
//    self.helperView.nextArticleButton.tintColor = self.helperView.nextArticleButton.isEnabled ? self.view.tintColor : [UIColor colorWithWhite:0.5 alpha:1.f];
//    [self.helperView.nextArticleButton setNeedsDisplay];
    
    self.helperView.startOfArticle.enabled = NO;
    self.helperView.endOfArticle.enabled = YES;
}

#pragma mark -

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
            if (imageView.image) {
                [imageView updateAspectRatioWithImage:imageView.image];
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
    
    if (self.stackView.arrangedSubviews.count > 0) {
        weakify(self);
        
        [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            strongify(self);
            [self.stackView removeArrangedSubview:obj];
            [obj removeFromSuperview];
            
        }];
    }
    
    self.item = article;
    
    self.images = [NSPointerArray weakObjectsPointerArray];
    [self setupToolbar:self.traitCollection];
    
#ifdef DEBUG
    NSDate *start = NSDate.date;
#endif
    
    // add Body
    [self addTitle];
    
    self.stackView.hidden = YES;
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self scrollViewDidScroll:self.scrollView];
        
        CGSize contentSize = self.scrollView.contentSize;
        DDLogDebug(@"ScrollView contentsize: %@", NSStringFromCGSize(contentSize));
        
        contentSize.width = self.view.bounds.size.width;
        self.scrollView.contentSize = contentSize;
    });
}

#pragma mark - Drawing

- (void)addTitle {
    
    NSString *subline = formattedString(@"%@ • %@", self.item.author?:@"unknown", [(NSDate *)(self.item.timestamp) timeAgoSinceDate:NSDate.date numericDates:YES numericTimes:YES]);
    NSString *formatted = formattedString(@"%@\n%@\n", self.item.articleTitle, subline);
    
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineHeightMultiple = 1.125f;
    
    UIFont * titleFont = [UIFont boldSystemFontOfSize:baseFontSize * 2.2f];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:titleFont];
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : baseFont,
                                     NSForegroundColorAttributeName: UIColor.blackColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: @(-1.14f)
                                     };
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont systemFontOfSize:(baseFontSize * 1.125f) weight:UIFontWeightMedium]],
                                        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:0.54f],
                                        NSParagraphStyleAttributeName: para,
                                        NSKernAttributeName: @(-0.43f)
                                        };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:baseAttributes];
    [attrs setAttributes:subtextAttributes range:[formatted rangeOfString:subline]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    label.numberOfLines = 0;
    label.attributedText = attrs;
    label.preferredMaxLayoutWidth = self.view.bounds.size.width;
    
    [label sizeToFit];
    
    label.backgroundColor = UIColor.whiteColor;
    label.opaque = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.stackView addArrangedSubview:label];
    
    NSLayoutConstraint *leading = [label.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:-(LayoutPadding/3.f)];
    leading.priority = UILayoutPriorityRequired;
    leading.active = YES;
    
    NSLayoutConstraint *trailing = [label.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-LayoutPadding];
    trailing.priority = UILayoutPriorityRequired;
    trailing.active = YES;
    
}

#pragma mark -

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
    else if ([content.type isEqualToString:@"paragraph"]) {
        if (content.content.length)
            [self addParagraph:content caption:NO];
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
        parent.type = @"list";
        parent.items = @[content];
        
        [self addList:content];
    }
    else if ([content.type isEqualToString:@"hr"]) {
        
    }
    else {
        DDLogWarn(@"Unhandled node: %@", content);
    }
}

- (void)addParagraph:(Content *)content caption:(BOOL)caption {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, LayoutPadding * 2);
    
    Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
#ifdef DEBUG_LAYOUT
#if DEBUG_LAYOUT == 1
    para.backgroundColor = UIColor.blueColor;
#endif
#endif
    
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
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
}

- (void)addHeading:(Content *)content {
    
    if (_last && [_last isMemberOfClass:Paragraph.class]) {
        [self addLinebreak];
    }
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Heading *heading = [[Heading alloc] initWithFrame:frame];
    heading.delegate = self;
#ifdef DEBUG_LAYOUT
#if DEBUG_LAYOUT == 1
    heading.backgroundColor = UIColor.redColor;
#endif
#endif
    heading.level = content.level.integerValue;
    [heading setText:content.content ranges:content.ranges attributes:content.attributes];
    
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
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, height);
    
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
    
    if ([_last isMemberOfClass:Heading.class] || !_last || [_last isMemberOfClass:Paragraph.class])
        [self addLinebreak];
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
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
    
    NSString *url = [(content.url ?: [content.attributes valueForKey:@"src"]) stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    
    if ([content.attributes valueForKey:@"data-large-file"]) {
        url = [content.attributes valueForKey:@"data-large-file"];
    }
    
    imageView.URL = [NSURL URLWithString:url];
    
    [self addLinebreak];
    
    if ((content.alt && ![content.alt isBlank]) || (content.attributes && ![([content.attributes valueForKey:@"alt"] ?: @"") isBlank])) {
        Content *caption = [Content new];
        caption.content = content.alt ?: [content.attributes valueForKey:@"alt"];
        [self addParagraph:caption caption:YES];
    }

}

- (void)addGallery:(Content *)content {
    
    if ([_last isMemberOfClass:Heading.class]) {
        [self addLinebreak];
    }
    
    Gallery *gallery = [[Gallery alloc] initWithNib];
    gallery.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, 200.f);
    
    [self.stackView addArrangedSubview:gallery];
    // set images after adding it to the superview since -[Gallery setImages:] triggers layout.
    gallery.images = content.images;
    
    [self.images addPointer:(__bridge void *)gallery];
    gallery.idx = self.images.count - 1;
    
}

- (void)addQuote:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    Blockquote *para = [[Blockquote alloc] initWithFrame:frame];
    
    if (content.content) {
        [para setText:content.content ranges:content.ranges attributes:content.attributes];
    }
    else if (content.items) {
        
        NSMutableAttributedString *mattrs = [NSMutableAttributedString new];
        
        for (Content *item in content.items) { @autoreleasepool {
            NSAttributedString *attrs = [para.textView processText:item.content ranges:item.ranges attributes:item.attributes];
            
            [mattrs appendAttributedString:attrs];
            [mattrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        } }
        
        para.textView.attributedText = mattrs.copy;
        [para performSelectorOnMainThread:NSSelectorFromString(@"updateFrame") withObject:nil waitUntilDone:YES];
        
    }
    else {
        
    }
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.textView.delegate = self;
    
    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
}

- (void)addList:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    List *list = [[List alloc] initWithFrame:frame];
    [list setContent:content];
    
    frame.size.height = list.intrinsicContentSize.height;
    list.frame = frame;
    
    _last = list;
    
    list.delegate = self;
    
    [self.stackView addArrangedSubview:list];
    [list.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;}

- (void)addAside:(Content *)content
{
    if (content.items && content.items.count) {
        [self processContent:content];
        return;
    }
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Aside *para = [[Aside alloc] initWithFrame:frame];
    
    if ([_last isMemberOfClass:Heading.class])
        para.afterHeading = YES;
    
    [para setText:content.content ranges:content.ranges attributes:content.attributes];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
    
    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
}

- (void)addYoutube:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    Youtube *youtube = [[Youtube alloc] initWithFrame:frame];
    youtube.URL = [NSURL URLWithString:content.url];
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
    
    [youtube.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

- (void)addPre:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    Code *code = [[Code alloc] initWithFrame:frame];
    
    if (content.content) {
        code.attributedText = [self.codeParser parse:content.content];
    }
    else {
        
    }
    
    [self.stackView addArrangedSubview:code];
    
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

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint point = scrollView.contentOffset;
    // adding the scrollView's height here triggers loading of the image as soon as it's about to appear on screen.
    point.y += scrollView.bounds.size.height;
    
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.frame.size;
    
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
        else if (!imageview.image && contains && !imageview.isLoading) {
            DDLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageview.loading = YES;
                [imageview il_setImageWithURL:imageview.URL];
            });
        }
    } }
    
    CGFloat y = point.y - scrollView.bounds.size.height;
    
    BOOL enableTop = y > scrollView.bounds.size.height;
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
    
    __block NSString *subidentifier = [identifier substringFromIndex:identifier.length > 3 ? 3 : 0];
    
    DDLogDebug(@"Looking up anchor %@", identifier);
    
    NSArray <Paragraph *> *paragraphs = [self.stackView.arrangedSubviews rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        return [obj isMemberOfClass:Paragraph.class];
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
                
                NSString *subcompare = [compare substringFromIndex:compare.length > 3 ? 3 : 0];
                
                float ld = [identifier compareStringWithString:compare];
                DDLogDebug(@"href:%@ distance:%@", compare, @(ld));
                
                BOOL contained = [subcompare containsString:subidentifier] || [subidentifier containsString:subcompare];
                
                DDLogDebug(@"sub matching:%@", contained ? @"Yes" : @"No");
                
                // also check last N chars
                
                // the comparison is not done against 0
                // to avoid comparing to self
                if ((ld >= 1 && ld <= 6) && contained) {
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
        
        [self.scrollView setContentOffset:CGPointMake(0, yOffset) animated:YES];
        
        // animate background on paragraph
        asyncMain(^{
            required.layer.cornerRadius = 4.f;
            [UIView animateWithDuration:0.1 delay:0.5 options:kNilOptions animations:^{
                required.backgroundColor = [UIColor colorWithRed:255/255.f green:249/255.f blue:207/255.f alpha:1.f];
                
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    
    NSString *absolute = URL.absoluteString;
    
    if (absolute.length && [[absolute substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
        [self scrollToIdentifer:absolute];
        return NO;
    }
    
    if (interaction == UITextItemInteractionPreview)
        return YES;
    
    if (interaction == UITextItemInteractionPresentActions) {
        NSString *text = [textView.attributedText.string substringWithRange:characterRange];
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[text, URL] applicationActivities:nil];
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    else {
        SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
        config.entersReaderIfAvailable = YES;
        
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL configuration:config];
        
        [self presentViewController:sfvc animated:YES completion:nil];
    }
    
    return NO;
}

@end
