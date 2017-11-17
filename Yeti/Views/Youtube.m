//
//  Youtube.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Youtube.h"

@interface Youtube ()

@property (nonatomic, weak) UIWebView *webview;

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
        self.layer.cornerRadius = 8.f;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 6.f);
        self.layer.shadowRadius = 16.f;
        self.layer.shadowOpacity = 0.12f;
        
        UIWebView *webview = [[UIWebView alloc] initWithFrame:frame];
        webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:webview];
        _webview = webview;
        _webview.layer.cornerRadius = 8.f;
        _webview.clipsToBounds = YES;
        
    }
    
    return self;
}

#pragma mark -

- (void)setVideoID:(NSString *)videoID
{
    _videoID = videoID;
    
    if (_videoID)
        self.URL = formattedURL(@"https://www.youtube.com/watch?v=%@", _videoID);
}

- (void)setURL:(NSURL *)URL
{
    _URL = URL;
    
    if (_URL) {
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self.webview loadRequest:[NSURLRequest requestWithURL:_URL]];
        });
    }
}

@end
