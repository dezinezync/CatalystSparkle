//
//  DZWebViewController.m
//  Esfresco
//
//  Created by Nikhil Nigade on 2/5/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZWebViewController.h"

@interface DZWebViewController () <WKNavigationDelegate> {
    BOOL _setupConstraints;
}

@property (nonatomic, strong, readwrite) WKWebView *webview;

@end

@implementation DZWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hidesBottomBarWhenPushed = YES;
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.view addSubview:self.webview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.URL) {
        NSError *error = nil;
        NSString *html = [NSString stringWithContentsOfURL:self.URL encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            DDLogError(@"error loading file: %@\n%@", self.URL, error.localizedDescription);
        }
        else {
            [self.webview loadHTMLString:html baseURL:NSBundle.mainBundle.bundleURL];
        }
    }
}

#pragma mark -

- (WKWebView *)webview
{
    if (!_webview) {
        _webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
        _webview.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        _webview.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        _webview.scrollView.showsVerticalScrollIndicator = NO;
    }
    
    return _webview;
}

@end
