//
//  ArticleProvider.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#ifndef ArticleProvider_h
#define ArticleProvider_h

#import <Foundation/Foundation.h>

@class FeedItem;

@protocol ArticleProvider <NSObject>

- (BOOL)hasPreviousArticleForArticle:(FeedItem * _Nonnull)item;
- (BOOL)hasNextArticleForArticle:(FeedItem * _Nonnull)item;

- (FeedItem * _Nullable)previousArticleFor:(FeedItem * _Nonnull)item;
- (FeedItem * _Nullable)nextArticleFor:(FeedItem * _Nonnull)item;

- (void)didChangeToArticle:(FeedItem * _Nonnull)item;

- (void)userMarkedArticle:(FeedItem * _Nonnull)article read:(BOOL)read;

- (void)userMarkedArticle:(FeedItem * _Nonnull)article bookmarked:(BOOL)bookmarked;

@end

#endif /* ArticleProvider_h */
