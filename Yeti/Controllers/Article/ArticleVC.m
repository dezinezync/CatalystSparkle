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

#import <DZNetworking/UIImageView+ImageLoading.h>
#import "NSAttributedString+Trimming.h"
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>
#import "NSDate+DateTools.h"

#import <SafariServices/SafariServices.h>

static CGFloat const padding = 12.f;

@interface ArticleVC () <UIScrollViewDelegate, UITextViewDelegate> {
    BOOL _hasRendered;
    
    BOOL _isQuoted;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollBottom;
@property (weak, nonatomic) UIView *last; // reference to the last setup view.
@property (weak, nonatomic) id nextItem; // next item which will be processed
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;
@property (nonatomic, strong) NSPointerArray *images;

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
    
    self.images = [NSPointerArray weakObjectsPointerArray];
    
    self.scrollView.delegate = self;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    weakify(self);
    
    [[self.stackView arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        strongify(self);
        [self.stackView removeArrangedSubview:obj];
        [obj removeFromSuperview];
        
    }];
    
    [self setupToolbar:self.traitCollection];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    [self.loader startAnimating];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_hasRendered)
        return;
    
    _hasRendered = YES;
    
#ifdef DEBUG
    NSDate *start = NSDate.date;
#endif
    
    // add Body
    [self addTitle];
    
    NSUInteger idx = 0;
    
    self.stackView.hidden = YES;
    
    for (Content *content in self.item.content) { @autoreleasepool {
//        _nextItem = [self.item.content safeObjectAtIndex:idx+1];
        [self processContent:content];
        
        idx++;
    } }
    
//    self.item.primedContent = self.stackView.arrangedSubviews;
    
    [self.loader stopAnimating];
    [self.loader removeFromSuperview];
    
    self.stackView.hidden = NO;
    
    _last = nil;
    
#ifdef DEBUG
    DDLogInfo(@"Processing: %@", @([NSDate.date timeIntervalSinceDate:start]));
#endif
    
    if (self.item && !self.item.isRead)
        [MyFeedsManager article:self.item markAsRead:YES];
    
    weakify(self);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self scrollViewDidScroll:self.scrollView];
    });
    
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

#pragma mark -

- (void)addTitle {
    
    NSString *subline = formattedString(@"%@ • %@", self.item.author?:@"unknown", [self.item.timestamp timeAgoSinceNow]);
    NSString *formatted = formattedString(@"%@\n%@\n", self.item.articleTitle, subline);
    
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineHeightMultiple = 1.214285714f;
    
    UIFont * titleFont = [UIFont systemFontOfSize:36.f weight:UIFontWeightSemibold];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:titleFont];
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : baseFont,
                                     NSForegroundColorAttributeName: UIColor.blackColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: @(-1.14f)
                                     };
    
    NSDictionary *subtextAttributes = @{NSFontAttributeName: [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont systemFontOfSize:20.f weight:UIFontWeightMedium]],
                                        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:0.54f],
                                        NSParagraphStyleAttributeName: para,
                                        NSKernAttributeName: @(-0.43f)
                                        };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:baseAttributes];
    [attrs setAttributes:subtextAttributes range:[formatted rangeOfString:subline]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f)];
    label.numberOfLines = 0;
    label.attributedText = attrs;
    [label sizeToFit];
    
    [self.stackView addArrangedSubview:label];
    
    [label.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [label.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
    
}

- (void)processContent:(Content *)content {
    if ([content.type isEqualToString:@"container"]) {
        if ([(NSArray *)content.content count]) {
            
            NSUInteger idx = 0;
            
            for (NSDictionary *dict in (NSArray *)[content content]) { @autoreleasepool {
                
                Content *subcontent = [Content instanceFromDictionary:dict];
                
//                _nextItem = [(NSArray *)(content.content) safeObjectAtIndex:idx+1];
                
                [self processContent:subcontent];
                
                idx++;
            }}
        }
    }
    else if ([content.type isEqualToString:@"paragraph"] && content.content.length) {
        [self addParagraph:content caption:NO];
    }
    else if ([content.type isEqualToString:@"heading"] && content.content.length) {
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
        
//        if (content.content.length > 140)
//            [self addParagraph:content caption:NO];
//        else
            [self addAside:content];
        
    }
    else if ([content.type isEqualToString:@"youtube"]) {
        [self addYoutube:content];
    }
    else if ([content.type isEqualToString:@"gallery"]) {
        [self addGallery:content];
    }
    else {
        
    }
}

- (void)addParagraph:(Content *)content caption:(BOOL)caption {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
    
    if ([_last isKindOfClass:Heading.class])
        para.afterHeading = YES;
    
    if ([_last isKindOfClass:Paragraph.class]
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
    
    if ([_last isKindOfClass:Paragraph.class] && ![(Paragraph *)_last isCaption] && !para.isCaption) {
        
        // since the last one is a paragraph as well, simlpy append to it.
        Paragraph *last = (Paragraph *)_last;
        
        NSMutableAttributedString *attrs = last.attributedText.mutableCopy;
        
        NSAttributedString *newAttrs = [para processText:content.content ranges:content.ranges];
        
        [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        [attrs appendAttributedString:newAttrs];
        
        last.attributedText = attrs.copy;
        attrs = nil;
        newAttrs = nil;
        return;
    }
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
    
    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [para.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
}

- (void)addHeading:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Heading *heading = [[Heading alloc] initWithFrame:frame];
    heading.level = content.level.integerValue;
    heading.text = content.content;
    
    frame.size.height = heading.intrinsicContentSize.height;
    heading.frame = frame;
    
    _last = heading;
    
    [self.stackView addArrangedSubview:heading];
    
    [heading.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [heading.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

- (void)addLinebreak {
    // this rejects multiple \n in succession which may be undesired.
    if (_last && [_last isKindOfClass:UIView.class])
        return;
    
    // append to the para if one is available
    if (_last && [_last isKindOfClass:Paragraph.class]) {
        Paragraph *para = (Paragraph *)_last;
        
        NSMutableAttributedString *attrs = para.attributedText.mutableCopy;
        [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName: Paragraph.paragraphStyle}]];
        
        para.attributedText = attrs;
        
        return;
    }
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 24.f);
    
    UIView *linebreak = [[UIView alloc] initWithFrame:frame];
    
    [linebreak.heightAnchor constraintEqualToConstant:24.f].active = YES;
    
    _last = linebreak;
    
    [self.stackView addArrangedSubview:linebreak];
    
    [linebreak.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor].active = YES;
    [linebreak.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor].active = YES;
}

- (void)addImage:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    if (!CGSizeEqualToSize(content.size, CGSizeZero)) {
        frame.size.height = ceilf((content.size.height * frame.size.width) / content.size.width);
    }
    
    Image *imageView = [[Image alloc] initWithFrame:frame];
    
    _last = imageView;
    
    if (CGSizeEqualToSize(content.size, CGSizeZero) == NO && content.size.width == 1.f && content.size.height == 1.f) {
        imageView.hidden = YES;
    }
    
    [self.stackView addArrangedSubview:imageView];
    [imageView.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
    [imageView.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:0.f].active = YES;
    [imageView.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:0.f].active = YES;
    
    [self.images addPointer:(__bridge void *)imageView];
    imageView.idx = self.images.count - 1;
    imageView.URL = [NSURL URLWithString:[content.url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
    
    [self addLinebreak];
    
    if (content.alt && ![content.alt isBlank]) {
        Content *caption = [Content new];
        caption.content = content.alt;
        [self addParagraph:caption caption:YES];
    }
}

- (void)addGallery:(Content *)content {
    
    
    
}

- (void)addQuote:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    Blockquote *para = [[Blockquote alloc] initWithFrame:frame];
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    if (content.items && content.items.count) {
        _isQuoted = YES;
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            for (Content *subcontent in content.items) { @autoreleasepool {
                [self processContent:subcontent];
            }}
        });
        
        _isQuoted = NO;
    }
    
    para.textView.delegate = self;
    
    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [para.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
}

- (void)addList:(Content *)content {
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 32.f);
    
    List *list = [[List alloc] initWithFrame:frame];
    list.quoted = _isQuoted;
    
    if (_isQuoted && [_last isKindOfClass:Blockquote.class]) {
        Blockquote *quote = (Blockquote *)_last;
        [quote append:[list processContent:content]];
        
        frame.size.height = quote.intrinsicContentSize.height;
        quote.frame = frame;
        [quote setNeedsDisplayInRect:quote.bounds];
    }
    else {
        [list setContent:content];
        
        frame.size.height = list.intrinsicContentSize.height;
        list.frame = frame;
        
        _last = list;
        
        list.delegate = self;
        
        [self.stackView addArrangedSubview:list];
        [list.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
        [list.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
    }
}

- (void)addAside:(Content *)content
{
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    
    Aside *para = [[Aside alloc] initWithFrame:frame];
    
    if ([_last isKindOfClass:Heading.class])
        para.afterHeading = YES;
    
    [para setText:content.content ranges:content.ranges];
    
    frame.size.height = para.intrinsicContentSize.height;
    para.frame = frame;
    
    _last = para;
    
    [self.stackView addArrangedSubview:para];
    
    para.delegate = self;
    
    [para.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [para.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
}

- (void)addYoutube:(Content *)content {
    
    CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0);
    Youtube *youtube = [[Youtube alloc] initWithFrame:frame];
    youtube.URL = [NSURL URLWithString:content.url];
    
    _last = youtube;
    
    [self.stackView addArrangedSubview:youtube];
    
    [youtube.leadingAnchor constraintEqualToAnchor:self.stackView.leadingAnchor constant:padding].active = YES;
    [youtube.trailingAnchor constraintEqualToAnchor:self.stackView.trailingAnchor constant:-padding].active = YES;
    
    [self addLinebreak];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint point = scrollView.contentOffset;
    // adding the scrollView's height here triggers loading of the image as soon as it's about to appear on screen.
    point.y += scrollView.bounds.size.height;
    
    for (Image *imageview in self.images) { @autoreleasepool {
        
        BOOL contains = CGRectContainsPoint(imageview.frame, point);
        // the first image may be out of bounds of the scrollView when it's loaded.
        // check if it's frame is contained within the frame of the scrollView.
        if (imageview.idx == 0)
            contains = contains || CGRectContainsRect(scrollView.frame, imageview.frame);
        
//        DDLogDebug(@"Frame:%@, contains: %@", NSStringFromCGRect(imageview.frame), @(contains));
        
        if (!imageview.image && contains && !imageview.isLoading) {
            DDLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageview.loading = YES;
                [imageview il_setImageWithURL:imageview.URL];
            });
        }
    } }
    
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (interaction != UITextItemInteractionInvokeDefaultAction)
        return YES;
    
    SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
    config.entersReaderIfAvailable = YES;
    
    SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL configuration:config];
    
    [self presentViewController:sfvc animated:YES completion:nil];
    
    return NO;
}

@end
