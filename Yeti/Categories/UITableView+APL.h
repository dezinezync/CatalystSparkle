//
//  UITableView+APL.h
//  Yeti
//
//  Created by Nikhil Nigade on 03/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#ifndef UITableView_APL_h
#define UITableView_APL_h

@interface UITableView (ApplePrivateMethods)
- (BOOL)highlightRowAtIndexPath:(id)arg1 animated:(BOOL)arg2 scrollPosition:(int)arg3;
- (void)unhighlightRowAtIndexPath:(id)arg1 animated:(BOOL)arg2;
- (void)_selectRowAtIndexPath:(id)arg1 animated:(BOOL)arg2 scrollPosition:(int)arg3 notifyDelegate:(BOOL)arg4;
- (void)_deselectRowAtIndexPath:(id)arg1 animated:(BOOL)arg2 notifyDelegate:(BOOL)arg3;
@end

#endif /* UITableView_APL_h */
