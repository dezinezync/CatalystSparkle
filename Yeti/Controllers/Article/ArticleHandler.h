//
//  ArticleHandler.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleProvider.h"

@class Article;

@protocol ArticleHandler <NSObject>

- (void)setupArticle:(Article * _Nonnull)article;

- (Article * _Nonnull)currentArticle;

@end
