//
//  SidebarVC+DragAndDrop.h
//  Elytra
//
//  Created by Nikhil Nigade on 05/10/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+SearchResults.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC (DragAndDrop) <
    UICollectionViewDragDelegate,
    UICollectionViewDropDelegate
>

@end

NS_ASSUME_NONNULL_END
