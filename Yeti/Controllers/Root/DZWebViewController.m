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
            __unused WKNavigation *navigation = [self.webview loadHTMLString:html baseURL:NSBundle.mainBundle.bundleURL];
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
        _webview.navigationDelegate = self;
        _webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    
    return _webview;
}

#pragma mark - <WKNavigationDelegate>

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([navigationAction.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else if ([navigationAction.request.URL.absoluteString isEqualToString:[NSBundle mainBundle].bundleURL.absoluteString]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        [UIApplication.sharedApplication openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    }
}

@end
