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

@protocol ArticleProvider <NSObject>

- (BOOL)hasPreviousArticleForArticle:(id _Nonnull)item;
- (BOOL)hasNextArticleForArticle:(id _Nonnull)item;

- (id _Nullable)previousArticleFor:(id _Nonnull)item;
- (id _Nullable)nextArticleFor:(id _Nonnull)item;

- (void)didChangeToArticle:(id _Nonnull)item;

- (void)userMarkedArticle:(id _Nonnull)article read:(BOOL)read;

- (void)userMarkedArticle:(id _Nonnull)article bookmarked:(BOOL)bookmarked;

@optional

- (void)userMarkedArticle:(id _Nonnull)article read:(BOOL)read completion:(void(^ _Nullable)(BOOL completed))completion;

- (void)userMarkedArticle:(id _Nonnull)article bookmarked:(BOOL)bookmarked completion:(void (^ _Nullable)(BOOL completed))completion;

@end

#endif /* ArticleProvider_h */
