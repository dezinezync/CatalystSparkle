//
//  FolderCell.m
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FolderCell.h"

@implementation FolderCell

- (void)configure:(Folder *)item indexPath:(NSIndexPath *)indexPath {
    
    self.folder = item;
    
    if (self.folder == nil) {
        return;
    }
    
    UIListContentConfiguration *content = [UIListContentConfiguration sidebarHeaderConfiguration];
    
    content.text = item.title;
    
    if (SharedPrefs.showUnreadCounts == YES) {
        
        item.unreadCountObservor = self;
        
        if (item.unreadCount.unsignedIntegerValue > 0) {
            
            content.secondaryText = item.unreadCount.stringValue;
            
        }
        
    }
    
    content.prefersSideBySideTextAndSecondaryText = YES;
    
    NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
    
    NSString *imageName = [snapshot isExpanded:item] ? @"folder" : @"folder.fill";
    
    content.image = [UIImage systemImageNamed:imageName];
    
    content.imageProperties.maximumSize = CGSizeMake(24.f, 24.f);
    
    self.contentConfiguration = content;
    
    UICellAccessoryOutlineDisclosure *disclosure = [UICellAccessoryOutlineDisclosure new];
    
    disclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
    
    self.accessories = @[disclosure];
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *updatedContent = (id)[self contentConfiguration];
    
    if (state.isExpanded == YES) {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder"];
        
    }
    else {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder.fill"];
        
    }
    
    self.contentConfiguration = updatedContent;
    
}

- (void)unreadCountChangedTo:(NSNumber *)count {
    
    /*
     * in iOS 14 - Beta 4, when a cell is expanded,
     * the primary cell is hidden and replaced with
     * with a visible cell at the same index path.
     * Because of this, we cannot reference *self* here.
     */
    
    FolderCell *cell = (id)[(UICollectionView *)[self.DS valueForKey:@"collectionView"] cellForItemAtIndexPath:[self.DS indexPathForItemIdentifier:self.folder]];
    
    if (cell == nil) {
        return;
    }
    
    UIListContentConfiguration *content = (id)[cell contentConfiguration];
    
    if (count.unsignedIntegerValue > 0) {
        content.secondaryText = count.stringValue;
    }
    else {
        content.secondaryText = nil;
    }
    
    cell.contentConfiguration = content;
    
}

@end