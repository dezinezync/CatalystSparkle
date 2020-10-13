//
//  FeedVC+DragAndDrop.m
//  Elytra
//
//  Created by Nikhil Nigade on 05/10/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+DragAndDrop.h"

@implementation FeedVC (DragAndDrop)

- (NSArray <UIDragItem *> *)tableView:(UITableView *)tableView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *article = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (article == nil) {
        return nil;
    }
    
    NSItemProvider *itemProvider = article.itemProvider;
    
    if (itemProvider == nil) {
        return nil;
    }
    
    UIDragItem *item = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    
    item.localObject = @{@"article": article,
                         @"cell": [tableView cellForRowAtIndexPath:indexPath],
                         @"DS": self.DS
    };
    
    return @[item];
    
}

@end
