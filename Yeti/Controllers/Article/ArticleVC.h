//
//  ArticleVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

@interface ArticleVC : UIViewController

- (instancetype _Nonnull)initWithItem:(FeedItem * _Nonnull)item;

@end
