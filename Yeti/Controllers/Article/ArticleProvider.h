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

@class Article;

@protocol ArticleProvider <NSObject>

- (BOOL)hasPreviousArticleForArticle:(Article * _Nonnull)item;
- (BOOL)hasNextArticleForArticle:(Article * _Nonnull)item;

- (Article * _Nullable)previousArticleFor:(Article * _Nonnull)item;
- (Article * _Nullable)nextArticleFor:(Article * _Nonnull)item;

- (void)didChangeToArticle:(Article * _Nonnull)item;

- (void)userMarkedArticle:(Article * _Nonnull)article read:(BOOL)read;

- (void)userMarkedArticle:(Article * _Nonnull)article bookmarked:(BOOL)bookmarked;

@end

#endif /* ArticleProvider_h */
