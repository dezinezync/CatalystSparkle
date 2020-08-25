//
//  Youtube.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Youtube.h"
#import "YetiConstants.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>

@interface Youtube ()

@property (nonatomic, weak) WKWebView *webview;

@end

@implementation Youtube

- (instancetype)initWithFrame:(CGRect)frame
{
    
    CGFloat const multiplier = (9.f/16.f);
    CGFloat height = frame.size.width * (9.f/16.f);
    
    if (frame.size.height == 0.f) {
        frame.size.height = height;
    }
    
    if (self = [super initWithFrame:frame]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.heightAnchor constraintEqualToAnchor:self.widthAnchor multiplier:multiplier].active = YES;
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        self.layer.cornerRadius = 8.f;
        self.clipsToBounds = YES;
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.allowsAirPlayForMediaPlayback = YES;
        configuration.allowsPictureInPictureMediaPlayback = YES;
        
        WKWebView *webview = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
        webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:webview];
        _webview = webview;
        _webview.layer.cornerRadius = 8.f;
        _webview.clipsToBounds = YES;
        _webview.scrollView.scrollEnabled = NO;
        _webview.opaque = YES;
        
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

#pragma mark -

- (void)setVideoID:(NSString *)videoID
{
    _videoID = videoID;
    
    if (_videoID != nil) {
        self.URL = formattedURL(@"https://www.youtube.com/watch?v=%@", _videoID);
    }
}

- (void)setURL:(NSURL *)URL
{
    _URL = URL;
    
    if (_URL) {
        weakify(self);
        
        runOnMainQueueWithoutDeadlocking(^{
            strongify(self);
            
            __unused WKNavigation * navigation = [self.webview loadRequest:[NSURLRequest requestWithURL:self->_URL]];
        });
        
    }
}

@end