//
//  CustomFeedCell.m
//  Elytra
//
//  Created by Nikhil Nigade on 17/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomFeedCell.h"

#import "Elytra-Swift.h"

@implementation CustomFeedCell

- (void)configure:(CustomFeed *)item indexPath:(nonnull NSIndexPath *)indexPath {
    // @TODO
//    UIListContentConfiguration *content = [UIListContentConfiguration sidebarCellConfiguration];
//
//    content.text = item.displayTitle;
//
//#if TARGET_OS_MACCATALYST
//    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
//#else
//    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
//#endif
//
//    content.prefersSideBySideTextAndSecondaryText = YES;
//
//    if (SharedPrefs.showUnreadCounts) {
//
//        if (indexPath.item == 0) {
//
//            if (MyFeedsManager.totalUnread > 0) {
//                content.secondaryText = [@(MyFeedsManager.totalUnread) stringValue];
//            }
//
//        }
//
//        if (indexPath.item == 1) {
//
//            if (MyFeedsManager.totalToday > 0) {
//                content.secondaryText = [@(MyFeedsManager.totalToday) stringValue];
//            }
//
//        }
//
//        if (indexPath.item == 2) {
//
//            if (MyFeedsManager.totalBookmarks > 0) {
//                content.secondaryText = [@(MyFeedsManager.totalBookmarks) stringValue];
//            }
//
//        }
//
//    }
//
//    content.image = [UIImage systemImageNamed:[(CustomFeed *)item imageName]];
//
//    content.imageProperties.tintColor = [(CustomFeed *)item tintColor];
//
//    self.contentConfiguration = content;
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *content = (id)[self contentConfiguration];
    
    UIBackgroundConfiguration *background = [[UIBackgroundConfiguration listSidebarCellConfiguration] updatedConfigurationForState:state];
    
    if (state.isSelected) {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = self.tintColor;
        background.backgroundColor = UIColor.systemFillColor;
        
    }
    else {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
        background.backgroundColor = UIColor.clearColor;
        
    }
    
    self.contentConfiguration = content;
    self.backgroundConfiguration = background;
    
}

@end
