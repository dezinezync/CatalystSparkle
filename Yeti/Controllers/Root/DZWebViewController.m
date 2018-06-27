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

- (void)loadView
{
    self.view = self.webview;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hidesBottomBarWhenPushed = YES;
    
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.evalJSOnLoad) {
        weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.webview evaluateJavaScript:self.evalJSOnLoad completionHandler:^(id _Nullable retval, NSError * _Nullable error) {
                
                strongify(self);
                self.evalJSOnLoad = nil;
                
                if (error) {
                    DDLogError(@"Attributions view error: %@", error);
                }
            }];
        });
    }
}

#pragma mark -

- (WKWebView *)webview
{
    if (!_webview) {
        _webview = [[WKWebView alloc] initWithFrame:UIScreen.mainScreen.bounds];
        _webview.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _webview.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        _webview.scrollView.showsVerticalScrollIndicator = NO;
    }
    
    return _webview;
}

@end
