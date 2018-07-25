//
//  FeedsVC+DragDrop.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC.h"
#import "FolderDrop.h"

@interface FeedsVC (DragDrop) <UITableViewDragDelegate, UITableViewDropDelegate, FolderDrop>

@end
