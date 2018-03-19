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
    
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.view addSubview:self.webview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.URL) {
        if ([NSFileManager.defaultManager fileExistsAtPath:self.URL.absoluteString]) {
            NSError *error = nil;
            NSString *html = [NSString stringWithContentsOfFile:self.URL.absoluteString encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                DDLogError(@"error loading file: %@\n%@", self.URL, error.localizedDescription);
            }
            else {
                [self.webview loadHTMLString:html baseURL:nil];
            }
        }
        else {
            DDLogError(@"The path %@ does not exist.", self.URL.absoluteString);
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
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        [UIApplication.sharedApplication openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    }
}

@end
