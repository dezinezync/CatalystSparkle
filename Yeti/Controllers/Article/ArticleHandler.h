//
//  ArticleHandler.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArticleProvider.h"

@protocol ArticleHandler <NSObject>

- (void)setupArticle:(id  _Nonnull)article;

- (id _Nullable)currentArticle;

@end
