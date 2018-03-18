//
//  DZWebViewController.h
//  Esfresco
//
//  Created by Nikhil Nigade on 2/5/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface DZWebViewController : UIViewController

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong, readonly) WKWebView *webview;

@end
