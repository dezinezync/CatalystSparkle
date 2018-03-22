//
//  ArticleHandler.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleProvider.h"

@class FeedItem;

@protocol ArticleHandler <NSObject>

- (void)setupArticle:(FeedItem * _Nonnull)article;

- (FeedItem * _Nonnull)currentArticle;

@end
